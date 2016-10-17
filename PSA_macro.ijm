macro_name    = "ParticleSizeAnalyzer Macro for ImageJ, PSA_macro.ijm (trunk). https://github.com/psa-rs/psa-macro" ;
macro_info    = "Ralph Sperling <ralphspg@gmail.com>, 2011 - 2016. Started at the Inorganic Nanoparticles Group, Institut Catala de Nanotecnologia (ICN), Barcelona, Spain. http://www.nanocat.org";
macro_license = "GNU General Public License v3, http://www.gnu.org/licenses/gpl.html";

macro_comment = "2016-10: Transferred the macro GitHub, no changes for the initial upload besides changing the filename.";

requires("1.49m");    //  not really, but let's get a recent version.. we have 2015! Feel free to change back and try..
// 1.43n was the last version in 2009. It got rid of the the message asking to save changes, even if the image had been saved by the macro before.
// See ImageJ News about updated versions:   http://rsbweb.nih.gov/ij/notes.html

FULL_AUTO_MODE = false;   // set true to skip configuration dialogues

// ============================================================================================

// ----------------------  Get options from preferences, or set to default values

// Apparently, there is no "parseBoolean()" in the macro language..
function parseBoolean(boolstring){ 
    if (boolstring == "true" || boolstring == true || boolstring == "1" || boolstring == 1){
        return(true); 
    } 
    else return(false);
}

choose_scale = newArray("NONE", "Position from last run", "Bottom left", "Bottom right", "TEM at UAB", "TEM at PCB", "TEM at PCB (large bar)", "TEM at PCB (auto find)");
oScalehelp = call("ij.Prefs.get", "PSA.scalehelp", "Position from last run");

choose_background=newArray("NONE", "Inverted Gaussian (10% image size)","Rolling Ball (10% image size)","Rolling Ball (r = 50 px)");
oRemoveBG   = call("ij.Prefs.get", "PSA.removeBG", "NONE");

choose_smoothing = newArray("NONE", "Median r = 1 (3x3)", "Median r = 2 (5x5)", "Median r = 3 (7x7)", "Gaussian r = 1", "Gaussian r = 2", "Gaussian r = 3");
// removed mean (Gaussian neither recommended):   "Mean r = 1 (3x3)", "Mean r = 2 (5x5)", "Mean r = 3 (7x7)" 
oSmooth = call("ij.Prefs.get", "PSA.smooth", "Median r = 1 (3x3)"); 

choose_thresh  = newArray("Manual (interactive)", "Automatic (ImageJ)", "Hysteresis (connectionthresholding*)", "Triangle (auto_threshold*)");
oThresh = call("ij.Prefs.get", "PSA.thresh", "Manual (interactive)"); 

choose_watershed = newArray("NONE", "Watershed filter");
oWatershed = call("ij.Prefs.get", "PSA.watershed", "Watershed filter"); 

oDiamMin = parseFloat(call("ij.Prefs.get", "PSA.diamMin", "2"));
oDiamMax = parseFloat(call("ij.Prefs.get", "PSA.diamMax", "999"));
oCircMin = parseFloat(call("ij.Prefs.get", "PSA.circMin", "0.8"));
oCircMax = parseFloat(call("ij.Prefs.get", "PSA.circMax", "1.0"));

oOutlineExcluded = parseBoolean(call("ij.Prefs.get", "PSA.outlineExcluded", "true"));

oTableExcluded = parseBoolean(call("ij.Prefs.get", "PSA.tableExcluded", "true"));

oShowOtherParameters = false;    // do not save this setting, i.e. the choice to configure more options


// ----------------------  Second window
oScaleunit = call("ij.Prefs.get", "PSA.scaleUnit", "nm");

oDarkBG = parseBoolean(call("ij.Prefs.get", "PSA.darkBG", "false"));

oSavePrepro = parseBoolean(call("ij.Prefs.get", "PSA.savePreprocessed", "false"));

//  Minimum size even for for excluded particles, everything smaller is assumed as noise
oSizeNoise = parseFloat(call("ij.Prefs.get", "PSA.sizeNoise", "1.0"));

oSaveResults    = parseBoolean(call("ij.Prefs.get", "PSA.saveResultsTable", "true"));

choose_histo    = newArray("0 - 50 nm / 0.5", "0 - 50 nm / 1.0", "0 - 100 nm / 0.5", "0 - 100 nm / 1.0", "0 - 200 nm / 1.0", "Automatic Binning", "NONE");
oHistShow       = call("ij.Prefs.get", "PSA.histoShow", "0 - 50 nm / 0.5");

oHistSavePNG    = parseBoolean(call("ij.Prefs.get", "PSA.histoSavePNG", "true"));

oHistSaveTXT    = parseBoolean(call("ij.Prefs.get", "PSA.histoSaveTXT", "false"));

oCalcCubes      = parseBoolean(call("ij.Prefs.get", "PSA.calculateCubes", "false"));
    
choose_merge    = newArray("Original image", "Preprocessed image");
oMergeOutlines  = call("ij.Prefs.get", "PSA.outlinedMergeWith", "Original image");

oSaveOutlines   = parseBoolean(call("ij.Prefs.get", "PSA.saveOutlined", "true"));

oLogfile        = parseBoolean(call("ij.Prefs.get", "PSA.saveLogfile", "true"));

oSaveOver       = parseBoolean(call("ij.Prefs.get", "PSA.saveOverExisting", "true"));

    
// ----------------------  Here, configure some HIDDEN OPTIONS not appearing in the dialog:
oStepwiseMode = false;   // for debugging, pops up a waiting message after each step (somewhat annoying feature..)
oWritesetfile = false;    // write settings from dialog to file

// Now all parameters should be preset

// ============================================================================================

if (FULL_AUTO_MODE == true){  // set some key parameters to automatic behaviour, another if clause below will close all windows
    oScalehelp = "NONE";
    oThresh = "Automatic (ImageJ)";
}
else {   // START WITH DIALOG

    // ----------------------  Dialog asking user for options

    Dialog.create("ParticleSizeAnalyzer");
    //Dialog.addMessage(macro_name);
    Dialog.addMessage("Designed for TEM images of nanoparticles\nCalculates the area-equivalent diameter of particles.");

    Dialog.addChoice("Help with scaling (interactive)", choose_scale, oScalehelp);

    Dialog.addChoice("Background removal", choose_background, oRemoveBG);
    Dialog.addChoice("Smoothing filter", choose_smoothing, oSmooth);

    Dialog.addMessage("..:: Segmentation and Analysis (* needs plugin installed) ::..");
    Dialog.addChoice("Thresholding mode", choose_thresh, oThresh);
    Dialog.addChoice("Separation of touching particles", choose_watershed, oWatershed);
    Dialog.addNumber("Minimum_diameter", oDiamMin);
    Dialog.addNumber("Maximum_diameter", oDiamMax);
    Dialog.addNumber("Minimum_circularity", oCircMin);
    Dialog.addNumber("Maximum_circularity", oCircMax);

    Dialog.addCheckbox("Outline excluded particles, too", oOutlineExcluded);
    Dialog.addCheckbox("Add excluded particles to results table (without saving these)", oTableExcluded);
    Dialog.addCheckbox("Configure less used options...", oShowOtherParameters);

    Dialog.show();


    // Now, get options and immediately write back to preferences
    oScalehelp  = Dialog.getChoice();   call("ij.Prefs.set", "PSA.scalehelp", oScalehelp);
    oRemoveBG   = Dialog.getChoice();   call("ij.Prefs.set", "PSA.removeBG", oRemoveBG);
    oSmooth     = Dialog.getChoice();   call("ij.Prefs.set", "PSA.smooth", oSmooth);

    oThresh     = Dialog.getChoice();   call("ij.Prefs.set", "PSA.thresh", oThresh);
    oWatershed  = Dialog.getChoice();   call("ij.Prefs.set", "PSA.watershed", oWatershed);
    oDiamMin    = Dialog.getNumber();   call("ij.Prefs.set", "PSA.diamMin", oDiamMin);
    oDiamMax    = Dialog.getNumber();   call("ij.Prefs.set", "PSA.diamMax", oDiamMax);
    oCircMin    = Dialog.getNumber();   call("ij.Prefs.set", "PSA.circMin", oCircMin);
    oCircMax    = Dialog.getNumber();   call("ij.Prefs.set", "PSA.circMax", oCircMax);

    oOutlineExcluded     = Dialog.getCheckbox();   call("ij.Prefs.set", "PSA.outlineExcluded", oOutlineExcluded);
    oTableExcluded       = Dialog.getCheckbox();   call("ij.Prefs.set", "PSA.tableExcluded", oTableExcluded);
    oShowOtherParameters = Dialog.getCheckbox();   call("ij.Prefs.set", "PSA.showOtherParameters", oShowOtherParameters);


    // ----------------------  Second screen with less-used options:
    if (oShowOtherParameters){                   
        Dialog.create("ParticleSizeAnalyzer (more options)");

        Dialog.addString("Scale unit (e.g. nm)", oScaleunit);
        Dialog.addMessage("When outlining particles smaller than minimum diameter:");
        Dialog.addNumber("Maximum size considered noise", oSizeNoise);


        Dialog.addCheckbox("Light particles on dark background", oDarkBG);
        Dialog.addCheckbox("Save_image_after preprocessing", oSavePrepro);

        Dialog.addCheckbox("Calculations and histogram for cubic particles", oCalcCubes);


        Dialog.addCheckbox("Save_results table as text file", oSaveResults);
        Dialog.addCheckbox("Save_histogram_image as PNG", oHistSavePNG);
        Dialog.addCheckbox("Save_histogram_data as TXT", oHistSaveTXT);
        Dialog.addChoice("Show diameter histogram", choose_histo, oHistShow);

            
        Dialog.addChoice("Merge outlined particles with", choose_merge, oMergeOutlines);
        Dialog.addCheckbox("Save_image_with outlined particles", oSaveOutlines);
        Dialog.addCheckbox("Save parameters in logfile", oLogfile);
        Dialog.addCheckbox("Save over existing macro output files (no timestamping)", oSaveOver);

        Dialog.show();

        oScaleunit      = Dialog.getString;     call("ij.Prefs.set", "PSA.scaleUnit", oScaleunit);
        //  Minimum size even for for excluded particles, everything smaller is assumed as noise
        oSizeNoise      = Dialog.getNumber;     call("ij.Prefs.set", "PSA.sizeNoise", oSizeNoise);


        oDarkBG         = Dialog.getCheckbox;   call("ij.Prefs.set", "PSA.darkBG", oDarkBG);
        oSavePrepro     = Dialog.getCheckbox;   call("ij.Prefs.set", "PSA.savePreprocessed", oSavePrepro);
        
        oCalcCubes      = Dialog.getCheckbox;   call("ij.Prefs.set", "PSA.calculateCubes", oCalcCubes);


        oSaveResults    = Dialog.getCheckbox;   call("ij.Prefs.set", "PSA.saveResultsTable", oSaveResults);
        oHistSavePNG    = Dialog.getCheckbox;   call("ij.Prefs.set", "PSA.histoSavePNG", oHistSavePNG);
        oHistSaveTXT    = Dialog.getCheckbox;   call("ij.Prefs.set", "PSA.histoSaveTXT", oHistSaveTXT);
        oHistShow       = Dialog.getChoice;     call("ij.Prefs.set", "PSA.histoShow", oHistShow);
        
        oMergeOutlines  = Dialog.getChoice;     call("ij.Prefs.set", "PSA.outlinedMergeWith", oMergeOutlines);
        oSaveOutlines   = Dialog.getCheckbox;   call("ij.Prefs.set", "PSA.saveOutlined", oSaveOutlines);
        oLogfile        = Dialog.getCheckbox;   call("ij.Prefs.set", "PSA.saveLogfile", oLogfile);
        oSaveOver       = Dialog.getCheckbox;   call("ij.Prefs.set", "PSA.saveOverExisting", oSaveOver);
    }

}  // close != FULL_AUTO_MODE block for interactive behaviour

// ============================================================================================
// ---------------------- Housekeeping



run("Appearance...", "  antialiased menu=12");  // Turn off interpolation to see only real pixels when zooming
removeScalebar = false;    // default value, scale bar can be set up to be automatically found and removed after scaling the image


imgtitle    = getTitle();
index = lastIndexOf(imgtitle, ".");
if (index!=-1) imgtitle = substring(imgtitle, 0, index);  // remove suffix
titlebase = imgtitle;

imgID       = getImageID();
filedir= split(getDirectory("image"),"\n");

if (filedir.length == 0){
	saveAs("Tiff");	
	filedir= split(getDirectory("image"),"\n");
}

imgdir      = filedir[0];
imgwidth    = getWidth();  // this is in pixels
imgheight   = getHeight();

print(titlebase);


print(imgdir);


// make timestamp string, taken from macro GetDateAndTime.txt
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
    TimeString=""+year+"-";
    if ((month+1)<10){TimeString=TimeString+"0";}
    TimeString = TimeString+(month+1)+"-";      //  don't know why, always get one month less :-/ a bug?
    if (dayOfMonth<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+dayOfMonth+"_";
    if (hour<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+hour+"h";
    if (minute<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+minute+"m";
    if (second<10) {TimeString = TimeString+"0";}
    TimeString = TimeString+second+"s";


if (! oSaveOver){       // do not put timestamp, i.e. overwrite files if already there from precedent run
    titlebase = titlebase+"_"+TimeString;
}

if (oMergeOutlines == "Preprocessed image"){
    oSavePrepro = true; // image has to be reloaded because proprocessed image will be further used as mask
}

if (oSavePrepro){
    preprofile = imgdir+titlebase+"_preprocessed.png";
}

// ---------------------- Write settings to file, may help to debug input from GUI

if (oWritesetfile){
    setfile = File.open(imgdir+titlebase+"_settings.txt");
    if (FULL_AUTO_MODE == true){ print(setfile, "FULL_AUTO_MODE = True");}   
    print(setfile, "oScalehelp = " + oScalehelp);   
    print(setfile, "oRemoveBG = " + oRemoveBG);  
    print(setfile, "oSmooth = " + oSmooth); 
    print(setfile, "oThresh = " + oThresh);
    print(setfile, "oWatershed = " + oWatershed);
    print(setfile, "oDiamMin = " + oDiamMin);
    print(setfile, "oDiamMax = " + oDiamMax);
    print(setfile, "oCircMin = " + oCircMin);
    print(setfile, "oCircMax = " + oCircMax);
    print(setfile, "oOutlineExcluded = " + oOutlineExcluded);
    print(setfile, "oTableExcluded = " + oTableExcluded);
    print(setfile, "oShowOtherParameters = " + oShowOtherParameters);

    print(setfile, "oScaleunit = " + oScaleunit);
    print(setfile, "oDarkBG = " + oDarkBG);
    print(setfile, "oStepwiseMode = " + oStepwiseMode); 
    print(setfile, "oSavePrepro = " + oSavePrepro);
    print(setfile, "oSizeNoise = " + oSizeNoise);
    print(setfile, "oSaveResults = " + oSaveResults);   
    print(setfile, "oHistShow = " + oHistShow); 
    print(setfile, "oHistSavePNG = " + oHistSavePNG);   
    print(setfile, "oHistSaveTXT = " + oHistSaveTXT);   
    print(setfile, "oMergeOutlines = " + oMergeOutlines);
    print(setfile, "oSaveOutlines = " + oSaveOutlines);
    print(setfile, "oLogfile = " + oLogfile);
    print(setfile, "oSaveOver = " + oSaveOver); 

    File.close(setfile); 
}

// ============================================================================================

// ---------------------- Set scale

getPixelSize(unit, pWidth, pHeight, pDepth);    // These are the values if scale etc is not set otherwise later
print("unit: ", unit);       // log
// print("pWidth: ", pWidth);
// print("pHeight: ", pHeight);
// print("pDepth: ", pDepth);


if (unit=="microns"){       // change scale to nm if found in microns, e.g. in Gatan .dm3 format
    run("Set Scale...", "known=1000 pixel=1 unit=nm");
}

if (oScalehelp == "Position from last run"){       // get saved values and draw line for scale bar
    scalelineX1 = call("ij.Prefs.get", "PSA.scalelineX1", 10);    // fall-back: long line 
    scalelineY1 = call("ij.Prefs.get", "PSA.scalelineY1", imgheight-10);    // at bottom
    scalelineX2 = call("ij.Prefs.get", "PSA.scalelineX2", imgwidth-10);
    scalelineY2 = call("ij.Prefs.get", "PSA.scalelineY2", imgheight-10);
    makeLine(scalelineX1, scalelineY1, scalelineX2, scalelineY2);
}


// Here favorite coordinates for the guess can be added,
// then also a label to the choose_scale array above in the prefernces
else if (oScalehelp == "Bottom left")   makeLine(20, imgheight-30, 300, imgheight-30);       
else if (oScalehelp == "Bottom right")  makeLine(imgwidth-300, imgheight-30, imgwidth-20, imgheight-30);    
else if (oScalehelp == "TEM at UAB")    makeLine(32, imgheight-40, 264, imgheight-40);      // for 140kV TEM from science building UAB (bottom left scale bar)
else if (oScalehelp == "TEM at PCB")    makeLine(1083, imgheight-26, 1364, imgheight-26);    // for Elisenda's TEM, 250k mag (bottom right scale bar)
else if (oScalehelp == "TEM at PCB (large bar)") makeLine(845, 1000, 1365, 1000);   // for Elisenda's TEM, new thin long scale bar

// this one tries to outline the scale bar with the WAND TOOL, starting coordinate = one pixel of the scale bar needed
else if (oScalehelp == "TEM at PCB (auto find)"){
    scaleX = 1355;   // x coordinate of starting point for wand tool to outline the scale bar  <-----<< CHANGE FOR YOUR SYSTEM
    scaleY = 999;    // y coordinate "
    removeScalebar = true;

    run("Set Scale...", "distance=NaN known=0 pixel=1 unit=pixel");   // unset scale

    doWand(scaleX, scaleY);  // outline scale bar with wand tool and known starting point

    run("Set Measurements...", "area bounding redirect=None decimal=3");
    run("Measure");

    // remove scale bar after having user entered scale
    // setBackgroundColor(255, 255, 255);
    // run("Clear", "slice");   // clear scale bar = fill with white

    lastindex = nResults-1;
    // print(lastindex);

    barX = getResult("BX", lastindex);  // TODO: How to get last measurement, or delete Results table first??
    barY = getResult("BY", lastindex); 
    barW = getResult("Width", lastindex);
    // print("barX = ", barX);
    // print("barY = ", barY);
    // print("barW = ", barW);

    makeLine(barX, barY, barX+barW, barY);
}    
        
if (oScalehelp != "NONE"){      // all interactive cases
    run("To Selection");
    setTool(4);
    scalemessage = "Please set yellow line to scale bar, then press OK to enter values.\n(Use + and - to zoom in and out)";
    waitForUser("USER INPUT: Manual adjustment", scalemessage);
    
    scaleStr = "unit="+oScaleunit; // +" global"; // the global option helps to have the same scale in next run
                                    // However, when multiple (already scaled) images are open, it creates a mess
    run("Set Scale...", scaleStr);
    
    // open the dialog and let user enter the known distance
    run("Set Scale...");

    getLine(scalelineX1, scalelineY1, scalelineX2, scalelineY2, linewidth); // get coordinates from line selection
    call("ij.Prefs.set", "PSA.scalelineX1", scalelineX1);   // save values for next run
    call("ij.Prefs.set", "PSA.scalelineY1", scalelineY1);
    call("ij.Prefs.set", "PSA.scalelineX2", scalelineX2);
    call("ij.Prefs.set", "PSA.scalelineY2", scalelineY2);
}
else{   //  = "NONE":  set line marker position to 0, needed later on for position of legend
    scalelineX1 = 0;
    scalelineX2 = 0;
    }
    
// get scale, i.e. length corresponding to one pixel, after (interactive) scaling
getPixelSize(unit, pWidth, pHeight, pDepth);

// print("unit: ", unit);       // log
// print("pWidth: ", pWidth);
// print("pHeight: ", pHeight);
// print("pDepth: ",pDepth);





// zoom out
run("Original Scale");


// ---------------------- Preprocessing
if (! oStepwiseMode) setBatchMode(true); 

run("Duplicate...", "title="+imgtitle+"_preprocessed");
processingID = getImageID();
selectImage(processingID);

//  convert image to 8-bit gray by default, TODO: is 8 bit necessary?
run("8-bit");   // bitDepth()
run("Grays");

if (oDarkBG) run("Invert");

if (removeScalebar){     // fill scale bar with background color
    setBackgroundColor(255, 255, 255);  // set to white
    doWand(scaleX, scaleY);     // outline again as defined in auto find option
    run("Clear", "slice");      // clear scale bar = fill with background color
    run("Select None");
}

if (oRemoveBG == "Rolling Ball (10% image size)"){      //  RollingBall0.1    TODO: test!
    rollingradius = 0.1*(imgwidth);    //  somewhat arbitrary,  r = 100 for a 1000 x 1000 px image, r = 50 seemed too small
    run("Subtract Background...", "rolling="+rollingradius+" light");
    log_removeBG = "background_removal = rolling_ball_radius_"+rollingradius;
}
else if (oRemoveBG == "Rolling Ball (r = 50 px)"){      // TODO: test!
    run("Subtract Background...", "rolling=50 light");
    log_removeBG = "background_removal = rolling_ball_radius_50";
}
else if (oRemoveBG == "Inverted Gaussian (10% image size)"){        // probably works best for little coverage
    selectImage(processingID);
    run("Invert");
    run("Duplicate...", "title=blurred"); blurredID = getImageID();
    blurradius = 0.05*(imgwidth + imgheight);    //  somewhat arbitrary,  r = 100 for a 1000 x 1000 px image
    run("Gaussian Blur...", "sigma="+blurradius);
    imageCalculator("Subtract", processingID, blurredID );
    selectImage(blurredID);
    close();
    selectImage(processingID);
    run("Invert");
    log_removeBG = "background_removal = inverted_gaussian_blur_radius_"+blurradius;
}
else{       // no background removal
    log_removeBG = "background_removal = NONE";
}

// choose_smoothing = newArray("Median r = 1 (3x3)", "Median r = 2 (5x5)", "Median r = 3 (7x7)", "Mean r = 1 (3x3)", "Mean r = 2 (5x5)", "Mean r = 3 (7x7)", "Gaussian r = 1", "Gaussian r = 2", "Gaussian r = 3", "NONE");

if (oSmooth == "Median r = 1 (3x3)") run("Median...", "radius=1");
else if (oSmooth == "Median r = 2 (5x5)") run("Median...", "radius=2");
else if (oSmooth == "Median r = 3 (7x7)") run("Median...", "radius=3");
// removing mean.. better use Gaussian or median 
// else if (oSmooth == "Mean r = 1 (3x3)") run("Mean...", "radius=1");
// else if (oSmooth == "Mean r = 2 (5x5)") run("Mean...", "radius=2");
// else if (oSmooth == "Mean r = 3 (7x7)") run("Mean...", "radius=3");
else if (oSmooth == "Gaussian r = 1") run("Gaussian Blur...", "sigma=1");
else if (oSmooth == "Gaussian r = 2") run("Gaussian Blur...", "sigma=2");
else if (oSmooth == "Gaussian r = 3") run("Gaussian Blur...", "sigma=3");

if (oSavePrepro) saveAs("PNG", preprofile);

if (oStepwiseMode) waitForUser("Preprocessing done.");

processingID = getImageID();    // just for the case..
selectImage(processingID);

// setBatchMode(false);

//  ---------------------- Segmentation
// choose_thresh  = newArray("def", "ImageJ default (manual)", "Hysteresis (connectionthresholding*)", "Triangle (auto_threshold*)");

if (oThresh == "Manual (interactive)"){     // manual interactive thresholding
    // setAutoThreshold();   // give a guess? However, this will overwrite previous settings..
    setBatchMode("exit & display");       // Display all windows
    run("Threshold...");
    setTool(4);   // select zooming tool
    waitForUser("USER INPUT: Manual adjustment","THRESHOLDING of preprocessed image:\n\nIf necessary adjust threshold with sliders, then press OK.\n(Use + and - to zoom in and out)\nSelecting autothresholding works from the dialog, too.");
  
}

if (oThresh == "Hysteresis (connectionthresholding*)"){
    // Automatic threshold by hysteresis (needs "connectionthresholding_" plugin installed!)
    // http://imagejdocu.tudor.lu/doku.php?id=plugin:segmentation:thresholding_by_connection:start
    run("connectionthresholding ");
    waitForUser("USER INPUT: Manual adjustment","THRESHOLDING of preprocessed image:\n\nIf necessary adjust threshold with sliders, then press OK.\n(Use + and - to zoom in and out)");
}

if (oThresh == "Triangle (auto_threshold*)"){   
    // Automatic threshold, triangle method (needs Auto_Threshold plugin installed!)
    // http://pacific.mpi-cbg.de/wiki/index.php/Auto_Threshold
    run("Auto Threshold", "method=Triangle");
}

starttime = getTime();   // after all interactive things, start time for benchmarking (preprosssing is not included)

if (oThresh == "Automatic (ImageJ)"){  
    setAutoThreshold();
}


if (! oStepwiseMode) setBatchMode(true); 

getThreshold(lowerthreshold, upperthreshold);
run("Convert to Mask");

if (oWatershed == "Watershed filter"){
    run("Watershed");
}

if (oStepwiseMode) waitForUser("Segmentation done.");

// now we have should have a black-and-white mask ready for the particle analyzer.
// Let's save it.
saveAs("PNG", imgdir+titlebase+"_maskALL.png");


// ---------------------- particle analyzer

// set Results window to display area and shape descriptors. Four decimals just for the case.
run("Set Measurements...", "area mean standard centroid center fit shape feret's perimeter redirect=None decimal=4");


// Check for oSizeNoise greater than oDiamMin, which caused some problems
if(oSizeNoise > oDiamMin){
    oSizeNoise = oDiamMin;
    print("Warning, oSizeNoise found greater than oDiamMin, setting it equal.");
}



// Convert size min and max to area, as expected from particle analyzer:
SizeMin     = PI*pow(oDiamMin/2, 2);
SizeMax     = PI*pow(oDiamMax/2, 2);
SizeNoise     = PI*pow(oSizeNoise/2, 2);

panalyzerStr = "size="+SizeMin+"-"+SizeMax ;
panalyzerStr = panalyzerStr+" circularity="+oCircMin+"-"+oCircMax ;
panalyzerStr = panalyzerStr+" show=Outlines display exclude clear summarize";
run("Analyze Particles...", panalyzerStr);

outlinesID = getImageID();

if (oStepwiseMode) waitForUser("Particle Analyzer done.");

if (oOutlineExcluded == 0){        // not needed any more
    selectImage(processingID);
    close();
}

// ---------------------- Calculations in Results table
selectWindow("Results");

particles_found = nResults;
diam   = newArray(nResults);
area   = newArray(nResults);
areaPX = newArray(nResults);
volume = newArray(nResults);
totalvol = 0.0;    // initialize as float - really necessary?

for (i=0; i<nResults; i++){
  area[i] = getResult('Area', i);              // read "Area" column into array, used later for stats for logfile
  diam[i] = 2.0*sqrt(area[i]/PI);
  volume[i] = 4.0/3.0*PI*pow(diam[i]/2.0, 3.0);
  areaPX[i] = area[i] / pow(pWidth, 2.0);    // area in PX using width, for non-square pixels there will be a problem
  setResult("AreaPX", i, areaPX[i]);
  setResult("Diameter", i, diam[i]);           // add diameters to results table
  setResult("Volume", i, volume[i]);
  totalvol += volume[i];
}

if (oCalcCubes){                    //  calculate edge length of cubic particles, from projected square
    selectWindow("Results");
    cubeedge = newArray(nResults);
    cubevol = newArray(nResults);
    for (i=0; i<nResults; i++){
        // area[i] = getResult('Area', i);    
        cubeedge[i] = sqrt(area[i]);
        cubevol[i] = pow(cubeedge[i], 3.0);
        setResult("CubeEdge", i, cubeedge[i]);        
        setResult("CubeVolume", i, cubevol[i]);
    }
}

updateResults();

if (oSaveResults) saveAs("Measurements", imgdir+titlebase+"_resultstable.txt");
if (oStepwiseMode) waitForUser("Results table done.");


// ---------------------- Histogram

// choose_histo = newArray("0 - 50 nm / 0.5", "0 - 50 nm / 1.0", "0 - 100 nm / 0.5", "0 - 100 nm / 1.0", "Automatic Binning", "NONE");


if (oHistShow != "NONE"){
    if (oCalcCubes){    // Make histogram of cube edge length
        if (oHistShow == "Automatic Binning"){
            run("Distribution...", "parameter=CubeEdge automatic");
        }
        else if (oHistShow == "0 - 50 nm / 0.5"){
            run("Distribution...", "parameter=CubeEdge or=100 and=0-50");
        }
        else if (oHistShow == "0 - 50 nm / 1.0"){
            run("Distribution...", "parameter=CubeEdge or=50 and=0-50");
        }
        else if (oHistShow == "0 - 100 nm / 0.5"){       
            run("Distribution...", "parameter=CubeEdge or=200 and=0-100");
        }
        else if (oHistShow == "0 - 100 nm / 1.0"){       
            run("Distribution...", "parameter=CubeEdge or=100 and=0-100");
        }
        histogramfilename=imgdir+titlebase+"_histogram_cubeedge";
    }
    else {      // make histogram of area-equivalent diameter assuming spherical particles 
        if (oHistShow == "Automatic Binning"){
            run("Distribution...", "parameter=Diameter automatic");
        }
        else if (oHistShow == "0 - 50 nm / 0.5"){
            run("Distribution...", "parameter=Diameter or=100 and=0-50");
        }
        else if (oHistShow == "0 - 50 nm / 1.0"){
            run("Distribution...", "parameter=Diameter or=50 and=0-50");
        }
        else if (oHistShow == "0 - 100 nm / 0.5"){       
            run("Distribution...", "parameter=Diameter or=200 and=0-100");
        }
        else if (oHistShow == "0 - 100 nm / 1.0"){       
            run("Distribution...", "parameter=Diameter or=100 and=0-100");
        }
        else if (oHistShow == "0 - 200 nm / 1.0"){       
            run("Distribution...", "parameter=Diameter or=200 and=0-200");
        }
        histogramfilename=imgdir+titlebase+"_histogram_CEdiam";
    }
    histogramID = getImageID();

    if (oHistSavePNG){
        //selectWindow("Diameter Distribution");
        histofilenamePNG = histogramfilename + ".png";
        saveAs("PNG", histofilenamePNG);
    }
    if(oHistSaveTXT){
        Plot.getValues(histobin, histocount);
        histofilenameTXT = File.open(histogramfilename+".txt");
        for (i=0; i<histobin.length; i++){
            print(histofilenameTXT,  histobin[i]+"\t"+histocount[i]);
        }
        File.close(histofilenameTXT);
    }
}


// ---------------------- Image with outlined particles

//  Place legend for outline colors below scalebar, bottom left or right

if ((scalelineX1+scalelineX2)/2 > imgwidth/2){        // then scale bar is on the right
    outlineLegendX = imgwidth-365;
    // rare case of "too circular" particles
    if (oCircMax < 1.0) outlineLegendX = imgwidth-440;
}
else outlineLegendX = 5;    // (scale bar and) Legend on left hand side
outlineLegendY = imgheight-5;   // Legend always at bottom of image


selectImage(outlinesID);
//run("Convert to Mask");
run("Invert");
run("8-bit");

if (oMergeOutlines == "Original image"){
    selectImage(imgID);
    run("Duplicate...", "title="+imgtitle+"_outlined.png");
    run("8-bit");   // bitDepth()
    outlinedID = getImageID();
}
else if (oMergeOutlines == "Preprocessed image"){
    open(preprofile);
    rename(imgtitle+"_outlined.png");
    run("8-bit");   // bitDepth()
    outlinedID = getImageID();
}

imageCalculator("Subtract", outlinedID, outlinesID);
run("RGB Color");

selectImage(outlinesID);
run("Green");
run("RGB Color");
imageCalculator("add", outlinedID, outlinesID);

selectImage(outlinedID);
setFont("SansSerif", 10); // , "antiliased");
setColor(0, 255, 0);
drawString("Matching all criteria", outlineLegendX, outlineLegendY);
if (oStepwiseMode) waitForUser("Particles matching size and circularity criteria outlined.");
selectImage(outlinesID);
close();

    
// ----------------------   Outline excluded particles as well
// todo: what about putting exclusion criterium as label, e.g. size or circularity?
// what about making (optional, additional) results table for exclude particles?

if (oOutlineExcluded){     
    setFont("SansSerif", 10);

        // TOO SMALL PARTICLES ("just too small" - circularity criteria have to be met)
    selectImage(processingID);
    analyzeStr =  "size="+oSizeNoise+"-"+SizeMin+" circularity="+oCircMin+"-"+oCircMax+" show=Outlines exclude";
    if (oTableExcluded) analyzeStr = analyzeStr + " display";
    run("Analyze Particles...", analyzeStr);
    exSmall = getImageID();
    run("Rename...","Too small particles");
    run("Invert");
    imageCalculator("Subtract", outlinedID, exSmall );  // first subtract the white outlines, then add the colored ones
    selectImage(exSmall);    // By a recent update, focus got lost somehow
    run("Magenta");   
    run("RGB Color");
    imageCalculator("Add", outlinedID, exSmall);
    
    selectImage(outlinedID);
    setColor(255, 0, 255);
    drawString("Too small size", outlineLegendX+110, outlineLegendY);
    selectImage(exSmall);
    if (oStepwiseMode) waitForUser("Too small particles outlined (excluded from analysis).");
    close();

        // TOO LARGE PARTICLES ("just too large" - circularity criteria have to be met)
    selectImage(processingID);
    analyzeStr =  "size="+SizeMax+"-infinity circularity="+oCircMin+"-"+oCircMax+" show=Outlines exclude";
    if (oTableExcluded) analyzeStr = analyzeStr + " display";
    run("Analyze Particles...", analyzeStr);
    exLarge = getImageID();
    run("Rename...","Too large particles");
    run("Invert");
    imageCalculator("Subtract", outlinedID, exLarge);
    selectImage(exLarge);    // By a recent update, focus got lost somehow
    run("Red");        
    run("RGB Color");
    imageCalculator("Add", outlinedID, exLarge);
    
    selectImage(outlinedID);
    setColor(255, 0, 0);
    drawString("Too large size",  outlineLegendX+195, outlineLegendY);
    selectImage(exLarge);
    if (oStepwiseMode) waitForUser("Too large particles outlined (excluded from analysis).");
    close();

         // NON-CIRCULAR PARTICLES (regardless of size but above oSizeNoise)
    selectImage(processingID);
    analyzeStr =  "size="+oSizeNoise+"-infinity circularity=0.0-"+oCircMin+" show=Outlines exclude";
    if (oTableExcluded) analyzeStr = analyzeStr + " display";
    run("Analyze Particles...", analyzeStr);
    exNonCirc = getImageID();
    run("Rename...","Too non-circular particles");
    run("Invert");
    imageCalculator("Subtract", outlinedID, exNonCirc);
    selectImage(exNonCirc);
    run("Yellow");   
    run("RGB Color");
    imageCalculator("Add", outlinedID, exNonCirc);
    
    selectImage(outlinedID);
    setColor(255, 255, 0);
    drawString("Non-circular", outlineLegendX+275, outlineLegendY);
    selectImage(exNonCirc);
    if (oStepwiseMode) waitForUser("Particles with too small circularity outlined (excluded from analysis).");
    close();

        // TOO-CIRCULAR PARTICLES: for the analysis of spherical particles, this is not appropriate..
    if (oCircMax < 1.0){
        selectImage(processingID);
        analyzeStr =  "size=0-infinity circularity="+oCircMax+"-1.0 show=Outlines exclude";
        if (oTableExcluded) analyzeStr = analyzeStr + " display";
        run("Analyze Particles...", analyzeStr);
        exTooCirc = getImageID();
        run("Rename...","Too circular particles (!?)");
        run("Invert");
        imageCalculator("Subtract", outlinedID, exTooCirc);
        // no color, leave white
        run("RGB Color");
        imageCalculator("Add", outlinedID, exTooCirc);

        selectImage(outlinedID);
        setColor(255, 255, 255);
        drawString("Too circular", outlineLegendX+350, outlineLegendY);
        selectImage(exTooCirc);
        if (oStepwiseMode) waitForUser("Particles with too large circularity outlined (excluded from analysis). (Do you want that?)");
        close();
    }
    selectImage(processingID);
    close();
    
    particles_excluded = nResults - particles_found;
    
    if (oTableExcluded){    // calculate diameter (and cube edge length), but not volume for excluded particles.
        for (i=0; i<nResults; i++){
            A = getResult('Area', i);
            setResult("Diameter", i, 2.0*sqrt(A/PI));   // add diameters to results table        onearea = getResult('Area', i);
            setResult("AreaPX", i, A/pow(pWidth, 2.0));    // add area in pixels
        }
        if (oCalcCubes){   // separate loop so condition will only get checked once
            for (i=0; i<nResults; i++){
                setResult("CubeEdge", i, sqrt(getResult('Area', i)));        // add cube edge length to results table
            }
        }
        updateResults();
    }
}

// TODO: see which way and which order is best - 
// Maybe display outlined particles before closing to have a quick check?
if (FULL_AUTO_MODE){  // close remaining windows

    selectImage(outlinedID);   // save image of outlined particles before closing
    setTool(11);
    if (oSaveOutlines) saveAs("PNG", imgdir+titlebase+"_outlined.png");

    selectImage(outlinedID);
    close();
    selectImage(histogramID);
    close();
    selectImage(imgID);
    close();    // close original image as well
}


if (FULL_AUTO_MODE == false){
    setBatchMode("exit & display");       // Display all remaining windows = outlined and histogram
            
    selectImage(outlinedID);   // save *after* displaying remaining windows, this should make the macro appear more responsive
    setTool(11);
    if (oSaveOutlines) saveAs("PNG", imgdir+titlebase+"_outlined.png");

    if (oHistShow != "NONE"){ 
        selectImage(histogramID);          // bring small histogram window to front
    }

}

    
// ---------------------- Logfile
stoptime = getTime(); 
processing_time += (stoptime-starttime)/1000;

if (oLogfile){
    logfile = File.open(imgdir+titlebase+"_logfile.txt");
        // Image information
    print(logfile, "macro_name = \""+macro_name+"\"");       // with double quotes
    print(logfile, "image_dir = \""+imgdir+"\"");             
    print(logfile, "image_title = \""+imgtitle+"\"");
    print(logfile, "analysis_timestamp = \""+TimeString+"\"");
    print(logfile, "width = "+imgwidth);
    print(logfile, "height = "+imgheight);
    print(logfile, "px_width = "+pWidth);
    print(logfile, "px_height = "+pHeight);
    print(logfile, "length_unit = \""+unit+"\"");
    if (oScalehelp != "NONE"){      // all interactive cases
        print(logfile, "scale_line_x1 = "+scalelineX1);
        print(logfile, "scale_line_y1 = "+scalelineY1);
        print(logfile, "scale_line_x2 = "+scalelineX2);
        print(logfile, "scale_line_y2 = "+scalelineY2);
    }
    else print(logfile, "scaling = non-interactive");
    
    print(logfile, "");

        // options
    print(logfile, "smoothing_filter = "+oSmooth);
    print(logfile, "background_removal = "+oRemoveBG);
    print(logfile, log_removeBG);
    print(logfile, "threshold_mode = "+oThresh);
    print(logfile, "threshold_lower = "+lowerthreshold);
    print(logfile, "threshold_upper = "+upperthreshold);
    print(logfile, "watershed_filter = "+oWatershed);
    print(logfile, "min_diameter = "+oDiamMin);
    print(logfile, "max_diameter = "+oDiamMax);
    print(logfile, "min_size_area = "+SizeMin);
    print(logfile, "max_size_area = "+SizeMax);
    print(logfile, "min_circularity = "+oCircMin);
    print(logfile, "max_circularity = "+oCircMax);
    print(logfile, "max_noise_diam = "+oSizeNoise);
    print(logfile, "max_noise_area = "+SizeNoise);
    print(logfile, "analyzer_string = \""+panalyzerStr+"\"");
    print(logfile, "");



        // Analysis results
    print(logfile, "particles_found = "+particles_found);
    print(logfile, "particles_excluded = "+particles_excluded);
    Array.getStatistics(area, min, max, mean, std);
    print(logfile, "area_mean = "+mean);
    print(logfile, "area_std = "+std);
    print(logfile, "area_min = "+min);
    print(logfile, "area_max = "+max);
    print(logfile, "");

    print(logfile, "Area-equivalent diameter for spherical particles (circle-equivalent, CEdiameter)");
    Array.getStatistics(diam, min, max, mean, std);
    print(logfile, "diameter_mean = "+mean);
    print(logfile, "diameter_std = "+std);
    print(logfile, "diameter_min = "+min);
    print(logfile, "diameter_max = "+max);
    print(logfile, "");
    meandiam = mean;     // store for volume-averaged volume

    Array.getStatistics(volume, min, max, mean, std);
    print(logfile, "volume_mean = "+mean);    // number-average
    print(logfile, "volume_std = "+std);
    print(logfile, "volume_min = "+min);
    print(logfile, "volume_max = "+max);

    print(logfile, "volume_total = "+totalvol);
    print(logfile, "volume_Vavg = "+ (4.0/3.0*PI*pow(meandiam/2.0,3.0)) );   // volume-average
    print(logfile, ""); 

    if (oCalcCubes){
        print(logfile, "Cube edge length (from projected area), USED FOR HISTOGRAM");
        Array.getStatistics(cubeedge, min, max, mean, std);
        print(logfile, "cubeedge_mean = "+mean);
        print(logfile, "cubeedge_std = "+std);
        print(logfile, "cubeedge_min = "+min);
        print(logfile, "cubeedge_max = "+max);
        print(logfile, "");
            
        Array.getStatistics(cubevol, min, max, mean, std);
        print(logfile, "cubevol_mean = "+mean);
        print(logfile, "cubevol_std = "+std);
        print(logfile, "cubevol_min = "+min);
        print(logfile, "cubevol_max = "+max);
        print(logfile, "");
    }

    print(logfile, "processing_time = "+processing_time+" s");
    print(logfile, "logfile_status = \"done\""); print(logfile, "");

    File.close(logfile);   // only one file can be opened at a time

    if (oStepwiseMode) waitForUser("Logfile done.");
}

// ---------------------- that's it.

