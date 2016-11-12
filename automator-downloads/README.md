# Automator downloads

OSX automator task to move
- Images
- Movies
- Music

files from `~/Downloads` to `~/Downloads/Media` directory right after download.

Note:
All image, movie and music files that have been downloaded **prior** to installing this workflow will stay in `~/Downloads` folder. The automator workflow takes care only the files downloaded after its installation.

## Prerequisites

The folder `~/Downloads/Media` must exits. Please crete it by finder or run the command in terminal below
```sh
mkdir ~/Downloads/Media
```


## Setup

### Open automator
Once downloaded double click on the `Downloads-Organize.workflow` file. It'll open up Automator and show configured actions.
![alt text](https://github.com/helyes/os-goodies/raw/master/automator-downloads/readme_assets/automator-downloads.png "Automator screenshot")


Sierra screenshot, might look different on newer macos versions.

### Adding automator task to `~/Download` folder

#### 1. Navigate to ~/Downloads folder in finder

I save the screenshot here...

#### 2. Right click then select Services on popup menu
![alt text](https://github.com/helyes/os-goodies/raw/master/automator-downloads/readme_assets/folder-popup.png "Folder popup")

#### 3. Click on Folder Actions Setup

![alt text](https://github.com/helyes/os-goodies/raw/master/automator-downloads/readme_assets/folder-action-setup.png "Folder popup")

#### 4. Add automator workflow to folder

![alt text](https://github.com/helyes/os-goodies/raw/master/automator-downloads/readme_assets/automator-configured.png "Folder popup")

Once configured as above all downloaded images, movies and music files will get moved under `~/Downloads/Media` folder.

#### TODO

1. create a script to init workflow
  - create directory if it does not exist
  - move media files from ~/Downloads to `~/Downloads/Media` directory
