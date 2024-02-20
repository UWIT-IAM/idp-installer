# IDP Installer

Ansible config to install idp-3.4 on IDP clusters

Target site needs some setup before first install

## Initial Install

```bash
# As root, on target
./system-setup.sh
```

## To install or upgrade the idp

```bash
./install.sh [ idp_eval | idp_prod ]
```

idp_eval = idpeval01  
idp_prod = idp01, idp02, ...

Note: Sometimes the install.yml has commented out disable/enable tasks. This
is to allow for a pre-disabled and idled host with no auto re-enable.

Note: Scripts and etc may have commented out gateway code.  This gateway is obsolete.

## Non-intrusive, on the fly upgrades

Attribute Resolver:

```bash
./install.sh -p attribute-resolver.yml idp_prod
```

Relying Party:

```bash
./install.sh -p relying-party.yml idp_prod
```

Views:

```bash
./install.sh -p views.yml idp_prod
```
