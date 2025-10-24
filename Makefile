# SPDX-FileCopyrightText: 2024 3mdeb <contact@3mdeb.com>
#
# SPDX-License-Identifier: Apache-2.0

SBINDIR ?= /usr/sbin
SYSCONFDIR ?= /etc
LIBDIR ?= /usr/lib

install:
	install -d $(DESTDIR)$(SBINDIR)/tui_callbacks

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
	install -m 0755 tui/tui_callbacks/* $(DESTDIR)$(SBINDIR)/tui_callbacks/

	install -m 0755 reports/dasharo-hcl-report.sh $(DESTDIR)$(SBINDIR)/dasharo-hcl-report
	install -m 0755 reports/touchpad-info.sh $(DESTDIR)$(SBINDIR)/touchpad-info

	install -d $(DESTDIR)$(SYSCONFDIR)/profile.d $(DESTDIR)$(SYSCONFDIR)/dts
	install -m 0755 dts-profile.sh $(DESTDIR)$(SYSCONFDIR)/profile.d
	install -m 0644 tui/dts-tui.yaml $(DESTDIR)$(SYSCONFDIR)/dts/dts-tui.yaml

	install -d $(DESTDIR)$(LIBDIR)/dts
	install -m 0644 tui/tui-lib.sh $(DESTDIR)$(LIBDIR)/dts/tui-lib.sh
