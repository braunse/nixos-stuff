{ config, lib, pkgs, ... }:

let
  # tikiPhp = pkgs.php74.withExtensions ({ all, enabled }: with all; enabled ++ [ xml dom mbstring ctype calendar iconv mysqli zip bz2 gd ]);
  # tikiComposer = pkgs.php74Packages.composer.override { php = tikiPhp; };
  adminer = pkgs.runCommand "adminer"
    {
      indexPhp = builtins.fetchurl {
        url = "https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1.php";
        sha256 = "sha256:1cy6p6jpxrfril63szf40jby3p1ayr8ra91r32ml7cl7z7cfdmrg";
      };
    } ''
    mkdir $out
    cp $indexPhp $out/index.php
  '';
  nginxPhpConfig = pool: ''
    fastcgi_split_path_info ^(.+?\.php)(/.*)$;
    if (!-f $document_root$fastcgi_script_name) {
       return 404;
    }

    fastcgi_param HTTP_PROXY "";
    fastcgi_pass unix:${config.services.phpfpm.pools.${pool}.socket};
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include ${pkgs.nginx}/conf/fastcgi_params;
    include ${pkgs.nginx}/conf/fastcgi.conf;
  '';

  nginxProxyPass = upstream: {
    proxyPass = upstream;
    extraConfig = ''
      proxy_set_header Host $host;
    '';
  };

  # xwikiConfig = rec {
  #   port = 3005;
  #   bind = "127.0.0.1";
  #   jdk = pkgs.openjdk11_headless;
  #   jetty = pkgs.jetty;
  #   version = "13.10.2";
  #   sha256 = "sha256:1anknrmndq3j2wkpl0jf390qlfhpd45azrp2vqzkv47synch4fzw";
  #   war = builtins.fetchurl {
  #     url = "https://nexus.xwiki.org/nexus/content/groups/public/org/xwiki/platform/xwiki-platform-distribution-war/${xwikiConfig.version}/xwiki-platform-distribution-war-${xwikiConfig.version}.war";
  #     inherit (xwikiConfig) sha256;
  #   };
  #   permDir = "/opt/xwiki";

  #   classpath = [
  #     { groupId = "org.hsqldb"; artifactId = "hsqldb"; version = "2.6.1"; sha256="sha256-4/np1HLZhble5cEO1A0DSWw6JrlQWQrgpJzmCGJty+g="; }
  #   ];

  #   startIni = [
  #     "--module=ext"
  #     "--module=resources"
  #     "--module=server"
  #     "--module=http"
  #     "--module=annotations"
  #     "--module=deploy"
  #     "--module=requestlog"
  #     "--module=websocket"
  #     "jetty.http.host=${bind}"
  #     "jetty.http.port=${toString port}"
  #     contextXml
  #   ] ++ (map (coords: let downloaded = pkgs.fetchMavenArtifact coords; in "--lib=${downloaded}/share/java/${coords.artifactId}-${coords.version}.jar") classpath);

  #   sysProps = [
  #     "-Dxwiki.data.dir=${permDir}/var"
  #   ];

  #   contextXml = pkgs.writeText "xwiki-context.xml" ''
  #     <!DOCTYPE Configure PUBLIC "-//Jetty//Configure//EN" "https://www.eclipse.org/jetty/configure_10_0.dtd">

  #     <Configure id="DeploymentManager" class="org.eclipse.jetty.deploy.DeploymentManager">
  #       <Get name="contexts">
  #         <Call name="addHandler">
  #           <Arg>
  #             <New class="org.eclipse.jetty.webapp.WebAppContext">
  #               <Set name="contextPath">/xwiki</Set>
  #               <Set name="war">${war}</Set>
  #             </New>
  #           </Arg>
  #         </Call>
  #       </Get>
  #     </Configure>
  #   '';
  # };
in
{
  services.unbound = {
    enable = true;
    settings = {
      server = {
        verbosity = 1;
        domain-insecure = [ "l0." ];
        local-zone = [ "l0. nodefault" ];
        do-not-query-localhost = "no";
      };
      stub-zone = [
        { name = "l0."; stub-addr = "127.0.0.1@1053"; }
        { name = "apps.alt0r.com"; stub-addr = "172.18.0.2"; }
      ];
    };
  };

  services.nsd = {
    enable = true;
    verbosity = 3;
    interfaces = [ "127.0.0.1@1053" "::1@1053" ];
    zones = {
      "l0." = {
        data = ''
          $ORIGIN l0.
          $TTL 300
          @ IN SOA ns.l0. admin.ns.l0. 127001001 300 300 1200 300
          @ IN NS 127.0.0.1
          *.l0. IN A 127.0.0.1
        '';
      };
    };
  };

  services.squid = {
    enable = true;
    configText = ''
      #
      # Recommended minimum configuration (3.5):
      #

      # Example rule allowing access from your local networks.
      # Adapt to list your (internal) IP networks from where browsing
      # should be allowed
      acl localnet src 10.0.0.0/8     # RFC 1918 possible internal network
      acl localnet src 172.16.0.0/12  # RFC 1918 possible internal network
      acl localnet src 192.168.0.0/16 # RFC 1918 possible internal network
      acl localnet src 169.254.0.0/16 # RFC 3927 link-local (directly plugged) machines
      acl localnet src fc00::/7       # RFC 4193 local private network range
      acl localnet src fe80::/10      # RFC 4291 link-local (directly plugged) machines

      acl SSL_ports port 443          # https
      acl Safe_ports port 80          # http
      acl Safe_ports port 21          # ftp
      acl Safe_ports port 443         # https
      acl Safe_ports port 70          # gopher
      acl Safe_ports port 210         # wais
      acl Safe_ports port 1025-65535  # unregistered ports
      acl Safe_ports port 280         # http-mgmt
      acl Safe_ports port 488         # gss-http
      acl Safe_ports port 591         # filemaker
      acl Safe_ports port 777         # multiling http
      acl CONNECT method CONNECT

      #
      # Recommended minimum Access Permission configuration:
      #
      # Deny requests to certain unsafe ports
      http_access deny !Safe_ports

      # Deny CONNECT to other than secure SSL ports
      http_access deny CONNECT !SSL_ports

      # Only allow cachemgr access from localhost
      http_access allow localhost manager
      http_access deny manager

      # We strongly recommend the following be uncommented to protect innocent
      # web applications running on the proxy server who think the only
      # one who can access services on "localhost" is a local user
      # We want to serve local dev stuff!
      # http_access deny to_localhost

      # Application logs to syslog, access and store logs have specific files
      cache_log       syslog
      access_log      stdio:/var/log/squid/access.log
      cache_store_log stdio:/var/log/squid/store.log

      # Required by systemd service
      pid_filename    /run/squid.pid

      # Run as user and group squid
      cache_effective_user squid squid

      #
      # INSERT YOUR OWN RULE(S) HERE TO ALLOW ACCESS FROM YOUR CLIENTS
      #


      # Example rule allowing access from your local networks.
      # Adapt localnet in the ACL section to list your (internal) IP networks
      # from where browsing should be allowed
      http_access allow localnet
      http_access allow localhost

      # And finally deny all other access to this proxy
      http_access deny all

      # Squid normally listens to port 3128
      http_port 3128

      # Leave coredumps in the first cache dir
      coredump_dir /var/cache/squid

      #
      # Add any of your own refresh_pattern entries above these.
      #
      refresh_pattern ^ftp:           1440    20%     10080
      refresh_pattern ^gopher:        1440    0%      1440
      refresh_pattern -i (/cgi-bin/|\?) 0     0%      0
      refresh_pattern .               0       20%     4320
    '';
  };

  networking.firewall.allowedTCPPorts = [ 3128 ];

  services.nginx = {
    enable = true;
    virtualHosts = {
      "__catch_all" = {
        serverName = "~^[A-Za-z0-9-]+-(?<dev_port>[0-9]+)[.]l0$";
        locations."/" = nginxProxyPass "http://127.0.0.1:$dev_port";
      };
      "adminer.l0" = {
        root = adminer;
        locations = {
          "/".index = "index.html index.php";
          "~ \.php$".extraConfig = nginxPhpConfig "general";
        };
      };
      "kc.l0" = {
        locations."/" = nginxProxyPass "http://127.0.0.1:3010";
      };
      "isgf-be.l0" = {
        locations."/" = nginxProxyPass "http://127.0.0.1:8055";
      };
      "isgf-portal.l0" = {
        locations."/" = nginxProxyPass "http://127.0.0.1:3000";
      };
      "bb.l0" = {
        locations."/".proxyPass = "http://nixos-dev1:3011";
      };
      "ctz.l0" = {
        locations."/" = nginxProxyPass "http://127.0.0.1:3050";
      };
    };
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  services.keycloak = {
    enable = true;
    httpPort = "3010";
    frontendUrl = "http://kc.l0/auth";
    database = {
      type = "postgresql";
      host = "127.0.0.1";
      port = 5432;
      username = "kcl0_keycloak";
      passwordFile = "/var/lib/localsecrets/kwl0_dev_pw";
      useSSL = false;
    };
  };
  systemd.services.keycloak.serviceConfig.ExecStart =
    lib.mkOverride 50 "${config.services.keycloak.package}/bin/standalone.sh -Dkeycloak.profile.feature.scripts=enabled";

  # services.phpfpm.pools.tikipool = {
  #   user = "tiki";
  #   phpPackage = tikiPhp;
  #   settings = {
  #     pm = "dynamic";
  #     "listen.owner" = config.services.nginx.user;
  #     "pm.max_children" = 5;
  #     "pm.start_servers" = 2;
  #     "pm.min_spare_servers" = 1;
  #     "pm.max_spare_servers" = 3;
  #     "pm.max_requests" = 500;
  #     "php_admin_value[error_log]" = "stderr";
  #     "php_admin_flag[log_errors]" = true;
  #     "catch_workers_output" = true;
  #   };
  #   phpEnv = {
  #     PATH = lib.makeBinPath (with pkgs; [
  #       tikiPhp
  #       tikiComposer
  #       mariadb-client
  #       gzip
  #       unzip
  #       rsync
  #       coreutils
  #       gnutar
  #       bzip2
  #       openssh
  #       sqlite
  #       tesseract
  #     ]);
  #   };
  #   phpOptions = ''
  #     memory_limit = 256M
  #     _file_uploads = On
  #     upload_max_filesize = 128M
  #     post_max_size = 132M
  #     max_execution_time = 120
  #     max_input_time = 120
  #     default_charset = "utf-8"
  #     session.save_path = /tmp
  #     mbstring.func_overload = 0
  #   '';
  # };

  services.phpfpm.pools.general = {
    user = "nobody";
    settings = {
      pm = "dynamic";
      "listen.owner" = config.services.nginx.user;
      "pm.max_children" = 2;
      "pm.start_servers" = 1;
      "pm.min_spare_servers" = 1;
      "pm.max_spare_servers" = 1;
      "pm.max_requests" = 500;
      "php_admin_value[error_log]" = "stderr";
      "php_admin_flag[log_errors]" = true;
      "catch_workers_output" = true;
    };
  };

  # users.users.tiki = {
  #   isSystemUser = true;
  #   home = "/opt/tiki";
  #   group = "tiki";
  # };

  # users.groups.tiki = {
  #   members = [ "nginx" ];
  # };

  # users.users.xwiki = {
  #   isSystemUser = true;
  #   home = "/opt/xwiki";
  #   group = "xwiki";
  # };

  # users.groups.xwiki = { };

  # systemd.services.xwiki = {
  #   enable = true;
  #   description = "XWiki";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "network.target" ];
  #   path = [ xwikiConfig.jdk ];
  #   serviceConfig = {
  #     WorkingDirectory = xwikiConfig.permDir;
  #     User = "xwiki";
  #     Group = "xwiki";
  #     ExecStart = "${xwikiConfig.jdk}/bin/java ${toString xwikiConfig.sysProps} -jar ${xwikiConfig.jetty}/start.jar ${toString xwikiConfig.startIni}";
  #   };
  # };
}
