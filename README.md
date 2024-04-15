# avd-rt-media-sandbox
AVD Media &amp; Entertainment L3LS sandbox

## Synopsis

This project is a sandbox 

* [[PR #3048] Doc: Media & Entertainment L3LS example #3048](https://github.com/aristanetworks/avd/pull/3048)<br>
* [[PR #3048] AVD example for Media & Entertainment customers using L3LS](https://ansible-avd--3048.org.readthedocs.build/en/3048/examples/media/index.html)<br>
* [6/22/23 Webinar: Automating Media and Entertainment Network Provisioning](https://www.youtube.com/watch?v=JD1v_mZN5H0)<br>

## Requirements

* __pyenv virtualenv + pip packages && ansible collections__<br>
    ```bash
    ./run -r
    ```
  __using git submodules__
  * __ansible-avd__
   
    __origin__
    ```bash
    # git submodule add --force --branch devel https://github.com/aristanetworks/avd.git submodules/ansible-avd
    git submodule add --force --branch devel https://github.com/mfdderome/avd.git submodules/ansible-avd
    ```
    __upstream__
    ```bash
    cd submodules/ansible-avd
    ```
    * __aristanetworks__
      ```bash
      git remote add aristanetworks https://github.com/aristanetworks/avd.git
      ```
    * __nielsjlarsen__
      ```bash
      git remote add nielsjlarsen https://github.com/nielsjlarsen/ansible-avd.git
      ```
    ```bash
    git remote -v
    ```
  * __ansible-cvp__
    ```bash
    git submodule add --force --branch devel https://github.com/aristanetworks/ansible-cvp.git submodules/ansible-cvp
    ```
  * __ansible-eos__
    ```bash
    git submodule add --force --branch main https://github.com/ansible-collections/arista.eos.git submodules/ansible-eos
    ```
  ```bash
  git submodule init
  git submodule update 
  ```
  :warning: __Modify the `collections_path` in `ansible.cfg` to enable `collections` or `submodules`__ :warning:
  ```bash
  ansible-galaxy collection list
  ```

* __For GNS3 on Archlinux__<br>
[GNS3 Arch Wiki](https://wiki.archlinux.org/title/GNS3)<br>
[GNS3 Installation on Archlinux based distros](https://www.gns3.com/community/discussions/gns3-installation-on-archlinux-based-distros)<br>
    ```bash
    yay -S ubridge dynamips
    ```
## Usage

* __build the M&E fabric__<br>
    ```bash
    ./run -b
    ```