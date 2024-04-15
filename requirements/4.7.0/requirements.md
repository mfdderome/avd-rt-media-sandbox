# pypy requirments

* __avd pip requirements__

  ```bash
  wget -O - -q https://raw.githubusercontent.com/aristanetworks/ansible-avd/v4.7.0/ansible_collections/arista/avd/requirements.txt | cat - >> requirements-avd.txt
  wget -O - -q https://raw.githubusercontent.com/aristanetworks/ansible-avd/v4.7.0/ansible_collections/arista/avd/requirements-dev.txt | cat - >> requirements-avd-dev.txt
  ```

* __extra pip requirements__
  ```bash
  touch requirements.txt
  cat << 'EOF' | tee -a requirements.txt >/dev/null
  pyOpenSSL>=23.2.0
  pandas>=2.1.0
  oauth2client>=4.1.3
  gspread>=5.11.1
  pynetbox>=7.2.0
  mergedeep>=1.3.4
  Unidecode>=1.3.6
  ansible-runner>=2.3.4
  GitPython>=3.1.36
  EOF
  ```

* __ansible-galaxy collection requirments__

```bash
touch requirements.yml
```

```bash
cat << 'EOF' | tee -a requirements.yml >/dev/null
collections:
  netbox.netbox:
    version: 3.14.0
EOF
```