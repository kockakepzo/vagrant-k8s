Vagrant alapú K8A környezet telepítése
---
Első lépésként töltsük le tetszőleges módon - git clone, wget, stb - Vagrantfile-t és a scripts könyvtárat a rendszerünkre, egy különálló könyvtárba, pl hwsw-k8s.

Második lépésként töltsük le a Virtualbox-ot az alábbi helyről a megfelelő rendszerre:
https://www.virtualbox.org/wiki/Downloads

A letöltés után telepítsük a csomagot, majd a VM VirtualBox Extension Pack csomagot is töltsük le és telepítsük.

Következő lépésként töltsük le és telepítsük a Vagrant-ot az alábbi oldalról a megfelelő rendszerre:
https://www.vagrantup.com/downloads

Amint a Virtualbox és a Vagrant is települt a rendszerre indítsunk parancsort - windowson a cmd.exe-t - és a 
könyvtárban, ahol a Vagrantfile található, adjuk ki a következő parancsot:
vagrant up

Várjuk meg a telepítés végét, majd be tudunk lépni a Kubernetes master node-ra az alábbi paranccsal:
vagrant ssh master-node

Amennyiben a Putty-t szeretnénk használni Windows rendszeren ssh kapcsolat létrehozására, úgy a következő lépésben 
töltsük le az MSI verziójú telepítőt az alábbi linkről, majd telepítsük:
https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html

Telepítés után a cmd.exe-t indítva az alábbi parancsot adjuk ki:

vagrant plugin install vagrant-multi-putty

Ezután a cmd.exe indítása után a következő paranccsal tudunk belépni a rendszerre:
vagrant putty master-node