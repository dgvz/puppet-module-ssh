# Setup an SSH server, and set a few basic, common configuration parameters.
#
define ssh::server($protocol_version  = 2,
                   $password_auth     = true,
                   $forward_x11       = false,
                   $permit_root_login = "without-password") {
	include ssh::packages

	ssh::noop {
		"ssh/server/installed":  require => Ssh::Noop["ssh/packages/installed"];
		"ssh/server/configured": require => Ssh::Noop["ssh/server/installed"];
	}

	case $::operatingsystem {
		RedHat,CentOS: {
			$ssh_service   = "sshd"
			$ssh_hasstatus = true
			$ssh_restart   = "/sbin/service sshd reload"
		}
		Debian: {
			$ssh_service   = "ssh"
			$ssh_hasstatus = false
			$ssh_restart   = "/etc/init.d/ssh reload"
		}
		default: {
			fail("Unknown \$::operatingsystem; please improve ssh::server")
		}
	}

	ssh::sshd_config {
		"Protocol":                        value => $protocol_version;
		"PermitEmptyPasswords":            value => no;
		"ChallengeResponseAuthentication": value => no;
		"SyslogFacility":                  value => AUTHPRIV;
		"LogLevel":                        value => INFO;
		"PasswordAuthentication":
			value => $password_auth ? {
				true  => yes,
				false => no,
			};
		"X11Forwarding":
			value => $forward_x11 ? {
				true  => yes,
				false => no,
			};
		"PermitRootLogin":
			value => $permit_root_login ? {
				true               => yes,
				false              => no,
				"without-password" => "without-password",
			};
	}

	service { $ssh_service:
		ensure    => running,
		enable    => true,
		hasstatus => $ssh_hasstatus,
		restart   => $ssh_restart,
		subscribe => Ssh::Noop["ssh/server/configured"];
	}
}
