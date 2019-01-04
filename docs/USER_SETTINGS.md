## Pre-processing Parameters
This document gives further instructions for the settings which are defined in `pre_processing.m`.  When you run `ea_interactive_masclab`, you will be asked to define these settings or select a previously processed season for which you have already defined settings.

### Settings
Parameter | Description | Typical value (if applicable)
--------- | ----------- | -----------------------------
**pathToFlakes** | Where the snowflake images are located.  Images **do not** need to be in a set directory hierarchy.  ea-masclab will recursively search the **pathToFlakes** for images that match the regular expression pattern.  This pattern is hard-coded in `pre_processing.m` as it is not expected to change (see the MASC-SPECIFIC FORMATTING section if this needs to be changed, or to make sure your image file names conform to the expected format). | n/a
**datestart**, **dateend** | Date range of snowflake images to process. | n/a
**isCamColor** | A vector of length 3 indicating whether each camera in the MASC took pictures in color. | n/a
**outputProcessedImgs** | _**NOT IMPLEMENTED**_ - this was meant to be a control to decide whether processed images should be output. However, its purpose is _deprecated_ since the cropped objects obtained from the original images are used for deriving all of the flake statistics. | n/a
**camFOV** | _This is an important setting._  These values define the field-of-view for each camera in the MASC (in units of pixels per mm).  The accuracy of these values is critical for reliability of derived statistics such as Max Diameter.  Typically, we determine these by dropping objects of known size through the MASC and assessing the max pixel diameter when the objects are in-focus.  Thusly, when an image is out of focus, derived statistics are less reliable since the object could either be small and close to the camera or large and far away. | Usually between 20 and 80 px/mm
**backgroundThresh** | Intensity threshold to discern between the background and the edge of an object.  A lower value will result in more and/or larger objects detected. | Default is 20, but we typically use 8-10.
**topDiscard**, **bottomDiscard**, **leftDiscard**, **rightDiscard** | These parameters can be used to mask out edges of the original image.  For example, **topDiscard** specifies the number of pixels to mask out (ignore) from the top of the image.  Often the left and right cameras (0 and 2) will get some reflection from the flash of the other side's camera, so you may need to apply a **leftDiscard** on camera 2 and a **rightDiscard** on camera 0.  Examine the original images to see if they have these reflections (see examples in this directory). | 250 for **leftDiscard**, 500 for **rightDiscard**
**applyTopDiscardToCams**, **applyBotDiscardToCams**, **applyLeftDiscardToCams**, **applyRightDiscardToCams** | For each of the sides that can be masked out, you can choose which camera each edge mask applies to.  If a discard applies to more than one camera, specify the cameras as a comma-delimited list (e.g. 0,1,2). | n/a
**lineFill** | Used for filling the area enclosed by edge detection of a cropped flake object.  This is specified in microns.  The default value is 200 but has not been thoroughly tested with other values.  Only some of the flake statistics modules analyze the filled area (others just rely on the edge or other flake statistics). | 200
**minFlakePerim** | Minimum perimeter of an object to be cropped from the original image (in pixels). Helps to avoid getting really tiny objects. | 250
**minCropWidth** | Minimum dimensions of the box that encloses a cropped object (in pixels). Also helps avoid getting really tiny objects. | 40
**maxEdgeTouch** | The maximum length that an edge of the detected object can be along the edge of the image (in pixels). This prevents getting objects with a substantial portion outside of the original image frame. Set to low values if you do not want any "partial" objects (i.e. flakes that go off the cropped image). | 100
**avgFlakeBrightness** | The minimum acceptable average pixel intensity of a cropped object (possible values 0-255).  Helps to avoid getting really dim objects. | 10
**filterFocus** | Indicate whether you want cropped objects to be filtered by how in-focus they are.  Our default focus value is not perfect, but it does help to eliminate ones that are clearly out of focus (or rather dim). | We often turn this on (set to 1)
**focusThreshold** | The threshold to use on the focus value if **filterFocus** is turned on. | 15
**internalVariability** | _**NOT USED**_ | n/a
**flakeBrighten** | _**NOT USED**_ | n/a
**siteName** | Set this to the location of the MASC. It is preferred that this be all lowercase with no white space. | e.g. 'alta'
**cameraName** | This may be useful if you have more than one MASC at a site. It is preferred that this has no white space. | e.g. 'MASC1'
**rescanOriginals** | After running Scan & Crop, ea-masclab remembers which original images it has already scanned. If you want to rescan these, you can do so by settings this to 1 and running Scan & Crop again. _**However**_, note that this will output all new cropped images, which may or may not overwrite what you already have depending on whether you've changed other settings. _We do not typically use this feature, rather electing to re-process seasons from scratch when necessary. | 0 or 1
**skipProcessed** | _**NOT USED**_ | n/a

If you have any questions about these parameters, feel free to contact [mrfrodo24](https://github.com/mrfrodo24) or srrhodes@ncsu.edu
