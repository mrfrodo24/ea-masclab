# ea-masclab <a name="ea-masclab">
MASC processing suite developed by [Environment Analytics](http://environmentanalytics.com).

This suite of Matlab functions and scripts processes image sets obtained from a Multi-Angle Snowflake Camera ([MASC](http://particleflux.net/)).  Processing of the raw images consists of these major steps, all of which can be accomplished by [ea-masclab](#ea-masclab).
  1. Scan all images and crop out meaningful objects (snow, rain, whatever may be dropped through for calibration, etc.).
  2. Compute various statistics to describe the shape and structure of each object.
  3. Output data into a usable format for further analysis (e.g. plotting or exporting to some other format).
  
  
## Usage

1. Clone the repository onto a machine where you can run Matlab (preferrably 2017a or higher, but you may be able to get by with as low as 2014a).  

    You will also want this machine to have enough storage to keep the raw MASC image set, the additional cropped images, and the statistics for each detected and cropped object.  **Note: All of this can get quite large**, especially if you are processing an entire winter season (probably between 10^5 and 10^6 images, depending on the number of storms observed).  

    Our research group has servers with upwards of 50TB of storage available.  *You can expect to need on average about **50 GB per winter season of data**.*
1. Open Matlab and navigate your Matlab working directory to the ea-masclab repo you just cloned.

1. Run `ea_interactive_masclab` in the command window

1. You will be prompted first to set where the image set is located on the machine.  From there, continue to follow the instructions for defining other user settings.  When you get to the end, enter `Y` to save the settings and continue.

    If you aren't sure what a processing parameter is used for, please see the table [here](#user-settings-reference).

1. The next prompt will ask you if you want to run Scan & Crop.  This is the first step of processing, *but only needs to be done **once**.*  If you are processing a large amount of data, please consider using the Scan & Crop caller script (see notes below).  Also, given that this step will take a while (potentially a few days), you may want to consider running this step in a background shell.  The standard way I do this is with the linux [screen](http://dasunhegoda.com/unix-screen-command/263/) command.  

    If you're just running a small image set (say an hour of a storm or some calibration data), enter `Y` to go ahead and run Scan & Crop on this new image set.

    For processing a large image set, this step has been known to crash at times due to presumed memory leaks within Matlab.  In Matlab 2016a and later, this has not happened as often.  However, I do still use a solution we already have for this.  See `utils/scan_crop_caller.sh` for a script that will be able to run Scan & Crop on the most recently used image set, but will restart Matlab every so often to circumvent the build up of memory leaks.  **If you choose to use this, enter `n` and then choose to Save and Exit the suite at the next prompt** (which will be the main menu).

    *Note: This step will save cropped objects to a `CROP_CAM` directory, placed in the directory of the original image.*

1. Once you have successfully completed Scan & Crop (either in the previous step or with the caller script), you are ready to use the main menu.  Here are the options you'll have at the main menu:

* ___Select Modules to Process___ - Run image analysis on set of cropped objects to describe their shape and structure.  Statistics are saved into `.mat` files in a `cache` folder placed within the path to the original image set.  You will be able to select the individual modules you want to run to obtain or refresh just the statistics you want.
* ___Run Scan & Crop___ - You can run Scan & Crop from the menu here.  If you have added new raw images to an image set, you may need to re-run Scan & Crop to go through the new images.  By default, it won't re-scan the old raw images.  However, you can change this behavior via the user settings.
* ___Redefine Processing Parameters___ - Make changes to the saved user settings.  In this suite, user settings are saved for each image set you add.  Anytime you specify a new directory for `pathToFlakes`, you're assumed to be processing a different set of images.  Hence why you are asked to pick the image set directory before making changes.
* ___Export Statistics___ - Right now, the primary way of exportation is to the `MASCtxt` files.  This is the first option when you choose to Export Statistics.  *Option (2), saving to Flake txt files, is deprecated.*
* ___Sync Cached Path___ - This option is to be used when you have added new images to a directory that's already been processed.  If you do not run this before running Scan & Crop, it will not know the new images are there.


## Contributions
You may submit pull requests as you please, and we will get to them asap.  Please file any bugs you encounter in the issues part of this repo.  Probably the biggest areas for further development right now are the modules, where we want to continue to think of new ways to analyze the cropped objects (e.g. symmetry).


This README is still in progress, so if you have any questions, please feel free to message me!
