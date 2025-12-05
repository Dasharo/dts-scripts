# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

SBINDIR ?= /usr/sbin
SYSCONFDIR ?= /etc

install:
	install -d $(DESTDIR)$(SBINDIR)

	install -m 0755 include/dts-environment.sh $(DESTDIR)$(SBINDIR)
	install -m 0755 include/dts-functions.sh $(DESTDIR)$(SBINDIR)
	install -m 0755 include/dts-subscription.sh $(DESTDIR)$(SBINDIR)
	install -m 0755 include/hal/dts-hal.sh $(DESTDIR)$(SBINDIR)
	install -m 0755 include/hal/common-mock-func.sh $(DESTDIR)$(SBINDIR)

	install -m 0755 scripts/cloud_list.sh $(DESTDIR)$(SBINDIR)/cloud_list
	install -m 0755 scripts/dasharo-deploy.sh $(DESTDIR)$(SBINDIR)/dasharo-deploy
	install -m 0755 scripts/dts.sh $(DESTDIR)$(SBINDIR)/dts
	install -m 0755 scripts/dts-boot.sh $(DESTDIR)$(SBINDIR)/dts-boot
	install -m 0755 scripts/ec_transition.sh $(DESTDIR)$(SBINDIR)/ec_transition
	install -m 0755 scripts/logging.sh $(DESTDIR)$(SBINDIR)/logging
	install -m 0755 scripts/btg_key_validator $(DESTDIR)$(SBINDIR)

	install -m 0755 reports/dasharo-hcl-report.sh $(DESTDIR)$(SBINDIR)/dasharo-hcl-report
	install -m 0755 reports/touchpad-info.sh $(DESTDIR)$(SBINDIR)/touchpad-info

	install -d $(DESTDIR)$(SYSCONFDIR)/profile.d
	install -m 0755 dts-profile.sh $(DESTDIR)$(SYSCONFDIR)/profile.d
