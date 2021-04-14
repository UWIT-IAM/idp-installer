Ansible config to install idp-4.1 on IDP cluster
(from dev or eval)


Local host needs ansible
-------------------------------

$ virtualenv -p python3 installer-env
$ . ./installer-env/bin/activate
$ pip install ansible


Target site needs some setup before first install
-------------------------------------------------

(as root, on target)
# ./system-setup.sh
(more or less)


--------------------------------------------------

To install or upgrade the idp -- use this to see options

2) ./install.sh 

idp_eval = idpeval01
idp_prod = idp11, idp12, ...


Note.  Sometimes the install.yml has commented out disable/enable tasks.  
       This is to allow for a pre-disabled and idled host with no auto re-enable.

---------------------------------------------------

See "./install.sh products" to see less intrusive, on-the-fly partial updates

----------------------------------------------------
