# Roadmap

## AVD submodules

```bash
git submodule add --force --branch devel https://github.com/mfdderome/avd.git submodules/ansible-avd
```
* __add upstream__
    ```bash
    cd submodules/ansible-avd
    git remote -v
    ```
    ```bash
    git remote add upstream https://github.com/aristanetworks/avd.git
    ```
    ```bash
    git remote add nielsjlarsen https://github.com/nielsjlarsen/ansible-avd.git
    ```
    ```bash
    git remote -v
    ```
    ```bash
    git switch --create feature/media-routed-ports
    git push --set-upstream origin feature/media-routed-ports
    ```
    ```bash
    git fetch nielsjlarsen
    git switch 2901-m_and_e-l3ls-example
    ```

## Media example

```
cp -r submodules/ansible-avd/ansible_collections/arista/avd/examples/media/documentation/* ./documentation
cp -r submodules/ansible-avd/ansible_collections/arista/avd/examples/media/group_vars .
cp -r submodules/ansible-avd/ansible_collections/arista/avd/examples/media/intended .
cp submodules/ansible-avd/ansible_collections/arista/avd/examples/media/*.yml .
```

## GNS3

* __Bridging__

    [How to Configure Network Bridge on Linux?](https://www.zenarmor.com/docs/linux-tutorials/how-to-configure-network-bridge-on-linux)<br>
    [Bridging Network Interfaces in Linux](https://www.baeldung.com/linux/bridging-network-interfaces)<br>