{
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
      ruby = pkgs.ruby;
    in rec {
      formatter = pkgs.alejandra;

      packages.default = pkgs.writeScriptBin "furpoll" ''
        #!/usr/bin/env ruby
        URL = "https://www.furaffinity.net/msg/pms/"
        COOKIE = File.read(ARGV.shift).strip
        SUBJECT = ARGV.shift
        FROM = ARGV.shift
        TO = ARGV.shift

        out = `${pkgs.curl}/bin/curl -s -H"Cookie: #{COOKIE}" #{URL}`

        msg = []
        if out =~ /class="no-sub"/
          msg << "Need login again."
        else
          count = out.scan(/note-unread/).count
          if count > 0
            msg << "You've got mail! -- https://www.furaffinity.net/msg/pms/"
          end
          count = out.scan(/"\d+ Comment Notifications?"/).count
          if count > 0
            msg << "You've got a comment reply! -- https://www.furaffinity.net/msg/others/#comments"
          end
        end

        if msg.any?
          # This can surely not backfire.
          IO.popen(["/run/wrappers/bin/sendmail", "-t"], "r+") do |f|
            f.puts <<~OUT
              Subject: #{SUBJECT}
              From: #{FROM}
              To: #{TO}

              #{msg.join("\n")}

            OUT
            f.close_write
            print f.read
          end
        end
      '';

      devShells.default = packages.default;

      nixosModules.default = {
        config,
        lib,
        pkgs,
        ...
      }: let
        cfg = config.services.furpoll;
        inherit (lib) mkIf mkEnableOption mkOption types;
      in {
        options.services.furpoll = {
          enable = mkEnableOption "Enable the furpoll FurAffinity poller";
          package = mkOption {
            type = types.package;
            description = "Package to use for furpoll (defaults to this flake's).";
            default = self.packages.${system}.default;
          };
          user = mkOption {
            type = types.str;
            description = "User account to run furpoll as (defaults to 'furpoll', which it will create).";
            default = "furpoll";
          };
          group = mkOption {
            type = types.str;
            description = "Group user account belongs to (defaults to 'furpoll', which it will create).";
            default = "furpoll";
          };
          cookieFile = mkOption {
            type = types.path;
            description = "Path to file with cookie value to authenticate with FurAffinity.";
          };
          calendar = mkOption {
            type = types.str;
            description = "systemd calendar events to fire on.";
            default = "*-*-* 1,6,8,19,22:07:00";
          };
          subject = mkOption {
            type = types.str;
            default = "furpoll";
            description = "Subject: header in emails sent.";
          };
          from = mkOption {
            type = types.str;
            description = "From: header in emails sent.";
          };
          to = mkOption {
            type = types.str;
            description = "To: header in emails sent.";
          };
        };

        config = mkIf (cfg.enable) (let
          ruby = "${pkgs.ruby}/bin/ruby";
          furpoll = "${cfg.package}/bin/furpoll";
        in {
          users.groups.furpoll = mkIf (cfg.group == "furpoll") {};
          users.users.furpoll = mkIf (cfg.user == "furpoll") {
            description = "furpoll user";
            group = cfg.group;
            isSystemUser = true;
          };

          systemd.services.furpoll = {
            script = ''
              set -eu
              # NO CLAIMS ARE MADE AS TO THE SUITABILITY OF THE FOLLOWING
              # INTERPOLATIONS FOR ANY PURPOSE, EVEN MERCHANTABILITY(!!).
              ${ruby} -Eutf-8 ${furpoll} "${cfg.cookieFile}" "${cfg.subject}" "${cfg.from}" "${cfg.to}"
            '';
            serviceConfig = {
              Type = "oneshot";
              User = cfg.user;
            };
          };

          systemd.timers.furpoll = {
            wantedBy = ["timers.target"];
            timerConfig = {
              Unit = "furpoll.service";
              OnCalendar = cfg.calendar;
              Persistent = true;
            };
          };
        });
      };
    });
}
