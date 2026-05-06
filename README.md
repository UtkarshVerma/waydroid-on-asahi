# Waydroid on Asahi

I compiled the images using GCE VM, c2d-highcpu-112. Took me an hour to compile  both images excluding setup time.
Credits to [UtkarshVerma](https://github.com/UtkarshVerma) for the guide on building the images!

These images are built for:

- Apple Silicon / Asahi Linux
- ARM64-only Android userspace
- 16 KiB page size
- Mesa / Asahi graphics

## Known issues

- Camera support does not currently work.
- Google Apps are not included.
- This setup is experimental.
- These images are intended for Apple Silicon Asahi systems.
## Downloads

Download the latest files from the Releases page.

The release should contain:

```text
system.img
vendor.img
SHA256SUMS
````

## Install the images

Create Waydroid’s custom image directory:

```bash
sudo mkdir -p /etc/waydroid-extra/images
```

Copy the images:

```bash
sudo cp system.img vendor.img /etc/waydroid-extra/images/
```

Then re-initialize Waydroid:

```bash
sudo waydroid init -f
```

Restart the container:

```bash
sudo systemctl restart waydroid-container
```

Start a session:

```bash
waydroid session start
```

Launch the UI:

```Run it using the waydroid app in launchpad.. Running using waydroid show-full-ui did not work for me```

## Fix storage and downloads
Initially the storage mount will be broken and you'll be unable to download any 
apps or use internal storage.. To fix this


Clone this repositry.

Then run
```bash
./waydroid-storage
```

That runs the default repair flow:

- remount Android's emulated storage
- bind your host `~/Downloads` folder into Android's `Download` folder

Useful subcommands:

```bash
./waydroid-storage status
./waydroid-storage mount
./waydroid-storage bind
./waydroid-storage unbind
```

## Fix network

If Waydroid has no internet access, run the network helper from the repository
root:

```bash
sudo ./fix_waydroid_network.sh
```

It enables IPv4 forwarding and applies the Waydroid firewall rules for either
`firewalld` or `iptables`, depending on what the host is using. You do not
need to stop Waydroid first.

This helper is intended for Fedora Asahi systems using Waydroid's default
bridge-based networking and either `firewalld` or an `iptables`/
`iptables-legacy` compatibility path. 
## Verify that Android booted

Check Waydroid status:

```bash
waydroid status
```

Expected status should show both the session and container running:

```text
Session:   RUNNING
Container: RUNNING
```

Then verify Android boot completion:

```bash
sudo waydroid shell getprop sys.boot_completed
```

Expected output:

```text
1
```

## Troubleshooting


### `Polkit: Authentication failed`

Run initialization with `sudo`:

```bash
sudo waydroid init -f
```

### `Failed to get service waydroidplatform`

If Android booted but the UI does not open, restart the session and container:

```bash
waydroid session stop
sudo systemctl restart waydroid-container
waydroid session start
waydroid show-full-ui
```

Check whether Android actually booted:

```bash
sudo waydroid shell getprop sys.boot_completed
```

If it returns `1`, the container is running and the issue is likely with the UI
or Waydroid platform service.

A way I found to bypass this issue is to launch it directly from the shortcut waydroid created.

Useful logs:

```bash
waydroid log
sudo journalctl -u waydroid-container -b --no-pager | tail -100
```

### Confirm that custom images are being used

Waydroid should mount the images from:

```text
/etc/waydroid-extra/images/system.img
/etc/waydroid-extra/images/vendor.img
```

You can check the log:

```bash
waydroid log | grep /etc/waydroid-extra/images
```

## Notes

These images were built from LineageOS / Waydroid sources with Asahi Mesa support
enabled and 16 KiB page-size configuration applied.

The build process is not documented here because prebuilt images are provided.

For the build process, go [here](https://github.com/UtkarshVerma/waydroid-on-asahi).
