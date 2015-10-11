# LoveLiver

![live photo demo](https://raw.githubusercontent.com/mzp/LoveLiver/master/demo.gif)

LoveLiver is a CLI tool to create Apple's Live Photos from JPEG and MOV.

## Requirements

 * MacOS X 10.11 (El Capitan)
 * Photos.app

## Install
 
 1. Go to the releases page, find the version you want.
 2. Download the file. 
 3. Put the binary to somewhere you want (e.g. `/usr/local/bin`).
 4. Make sure it has execution bits turned on by `chmod a+x LoveLiver`.

## Usage

### Create Live Photos

```
$ ./LoveLiver --operation=livephoto --jpeg sample/original/IMG.JPG --mov sample/original/IMG.MOV --output sample/livephoto
finish writing.
```

and drop & drag `sample/livephoto` directory to `Photos.app`.

### Show metadata of JPEG

```
$ ./LoveLiver --operation=jpeg --jpeg sample/livephoto/IMG.JPG
asset identifier: CDDD4450-642F-442B-8371-B46BC4229XXY
```

### Show metadata of QuickTime MOV

```
$ ./LoveLiver --operation=mov --mov sample/livephoto/IMG.MOV
asset identifier: CDDD4450-642F-442B-8371-B46BC4229XXY
still image time: 0
```

## Acknowledge

 * [CommandLine](https://github.com/jatoben/CommandLine) is Copyright (c) 2014 Ben Gollmer and is licensed under [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
 * [Tda-style Hatsune Miku](https://bowlroll.net/file/4576) is created by tda.