using Toybox.WatchUi as Ui; 
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Math as Mt;
using Toybox.Time.Gregorian; //timeinfo
using Toybox.Time;
using Toybox.System;
using Toybox.StringUtil;
using Toybox.ActivityMonitor;
using Toybox.Sensor;
using Toybox.SensorHistory;
using Toybox.System;
using Toybox;

var gIntStartOfDayHour = 6; //6am start of day
var gIntFinishOfDayHour = 23; //10pm finish day
	
var gRowHeight = 35; 
var gIntYForBodyBattery = 31; //20
var customFontSmall = null; // esp for fenix style watches.
var gNumAPIMajorVersion = 0; // will be major version, usual 1, 2, or 3. 1 cannot have battery stats.
var gStrCurrentQuote = "I'll be happy if running and I can grow old together. Haruki Murakami";
var gStrDeviceName = ""; //default to blank - set to 235 later

var gIntHeartRate=0;
var gintDesiredBodyBattery; // eg 70
var gStrHRBackColour=Gfx.COLOR_BLACK;
var gStrHRFontColour=Gfx.COLOR_WHITE;
var gStrBBBackColour=Gfx.COLOR_BLACK;
var gStrBBFontColour=Gfx.COLOR_WHITE;		

//========================================================================
      var       gBlDebug   =       false;
//=========================================================================

//======================================================================
// notes by ATK
// to run this file in vs code
// you can just go to run \ debug
// to build for a different device, select View Command Pallette and then build for device
// to upload to website, I think export via View, Command Menu
// then go to https://apps.garmin.com/en-US/developer/dashboard

/*
class InputDelegate extends Ui.BehaviorDelegate {
		 public function initialize() {
			BehaviorDelegate.initialize();
		 }
		
    	function onKey(keyEvent) {
			System.println(keyEvent.getKey());  // e.g. KEY_MENU = 7
			System.println(keyEvent.getType()); // e.g. PRESS_TYPE_DOWN = 0
			return true;
   	 }
}// end class
*/

class AKInstinctQuotesStatsMoveBarView extends Toybox.WatchUi.WatchFace  {


	// how to build in vs code - select View Command and then  Export
    var strVersion = "v1.1"; // i for instinct version;// 
	
	// v1.1 2/01/2025 Add print out last hour and htis hour every 4 minutes
	// v1.0k - trying to save steps every 2 hours. 
	// 3.3g minor fixes to minutes etc. 
    // 25/7/2023 ATK -  v3.3a made seconds larger as I cant even see them on my watch
	// v3.3 change time internval between stats and words to 1 minute     var intChangeWordsToStatsIntervalMin = 1;
	// v3.2a added seconds - changed color and size of minutes 
	// 3.1f fix for negative vlues in body battery desired/ amount of day left
	// 3.1g change end of day to 11pm
	// 3.1a March 4 2023 - moved intStartOfDayHour and end to global for easier change and
	// visibility - slightly changed colours of body battery also color. 
	// may move down by a few pixels also
	// 3.1 March 2023 -function getBodyBatteryPercentAndSetColours() {
		//trying to change this to minutes.. but failing9:09am 28 March 2023
		//also addeing difference from ideal if red or purple colour
	// 3.0b Aug 11 - Change start of day for body battery to 6am
	// 3.0a fix bug
				// 3.0 July 22 - redoing how i count lines etc. a bit nicer. 
				// 2.9d July 22 - Changing from showing 5 lines history to 4 as 5 doesnt fit on 945
				// 2.9c calcculate diff body battery and day left in minutes not hours. 
				// 2.9b - add tolerance for body battery of 5... maybe or 10...
	// v2.9 just checking git
				// 2.8 colors for BB? based on hour approximately. Actually based on % day left 
				// 20 July 2022v 2.7 changed heart rate colours a little bit
				// 3.0 will be to change from BB to image of small man, and HR to a heart. 
				//  temp hide  heart  rate  if 0
				// 2.6 July 7 add body battery on front screen
				// 2.5 may add heart rate on front screen, white text, or red if higher than 100
				// 2.4a minor move of text for week to right
				// 2.3 and 2.4 fixed up buggy display for 235 watch
				// 2.2b change the weekly total to include todays amount
				// 2.1h fixes and colours for week total > 25km
				// 24/02/2022 - Fixed issues re changes yesterday
				//23/2/22 0- stop quotes from flickering so much
				//7/2/22 fix weekly kms no decmimal now. Fixed battery failure on 235 devices, ie less than 3 major version api
					//7/2/22 - also added decimal place for current daily steps and kms eg 0.2km
					//nipple on left 11/12/2021. Fix short day name eg Thur
    			// added battery yellow colour and red and background color for battery AND BIG BATTERY -- move battery up and left
	
	var customFontLarge = null;
    var intChangeWordsToStatsIntervalMin = 2; // do a mod 3 on the time to change... 
    var gNumberOfLinesToPrint=5;
    var gXForTextLoc = 5;
    var gIntFontSize=10;
    var gIntLastMoveBarLevel=0;
    var gIntNumberOfMovedHours= 0;
    
    var gStrPartNumberDevice = "";
    
    var gTinyFont = null;
	
	var myInputDelegate = new InputDelegate();
 var cloud;
 var heartIcon;

 public function initialize() {
        WatchFace.initialize();
		myInputDelegate.initialize();
        cloud = new WatchUi.Bitmap({:rezId=>Rez.Drawables.cloud,:locX=>120,:locY=>23});
		heartIcon = new WatchUi.Bitmap({:rezId=>Rez.Drawables.heart,:locX=>123,:locY=>6});

		//Session.start();
		}

    // Load your resources here
    function onLayout(dc) {
     customFontSmall = Ui.loadResource(Rez.Fonts.akSmallFont);
     customFontLarge = Ui.loadResource(Rez.Fonts.customFontLarge);
     gTinyFont = Gfx.FONT_XTINY; //customFontSmall;
     var mySettings = System.getDeviceSettings();
		gStrPartNumberDevice = mySettings.partNumber;
		Sys.println("Part number is '" + gStrPartNumberDevice + "'");
		// fenix 5 =006-B3110-00, fs = 006-B2544-00
		// forerunner 235 = 006-B2431-00
	
		

		// check which api/sdk version this device supports
			var apiversion = mySettings.monkeyVersion;
			var apiversionString = Lang.format("$1$.$2$.$3$", apiversion);
			System.println(apiversionString); //e.g. 2.2.5
		    gNumAPIMajorVersion = apiversion[0];
     		System.println(gNumAPIMajorVersion); //e.g. 2 or 1
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    
    // Update the view
    function onUpdate(dc) {

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
		
		var intYForTime = -2;
		var intXForTime=dc.getWidth()/2-21;
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
		var minute = clockTime.min;
		var second = clockTime.sec;
        if (!Sys.getDeviceSettings().is24Hour) {
        	hour = hour % 12;
        	if (hour==0) {
        		hour = 12;
        	}
        } // end if
  	 	var intStartDateLocationY=dc.getHeight()-48;


		var intXForHR = dc.getWidth()-22;
    	DrawTimeAndVersion(dc, intXForTime, intYForTime, clockTime, hour, minute, second);

		DrawHeartRateAndBodyBattery(dc,intXForHR, intYForTime);

		DrawWatchBatteryStats(dc, intXForHR, intYForTime);

		DrawWeeksMovementOrQuotesOrHourlySteps(dc, hour, minute, second);

		DrawCurrentDate(dc, intStartDateLocationY);
	 
	    DrawKMTravelledAndMoveBar(dc);

		 cloud.draw(dc);
         heartIcon.draw(dc);
	    	      	    	    
	} // end onUpdate

	
    // ==================================================================
	// can we also return the difference from ideal eg 70% (-10)
	// ==================================================================

	function DrawCurrentDate(dc, intDateStartYBatteryAndDate) {
	// reset color
	     dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
	    
	   	// =====================================================================	    
	    // Put the date	    
		// =====================================================================	

		var now = Time.now();
		var info = Gregorian.info(now, Time.FORMAT_LONG);
		var infoShort = Gregorian.info(now, Time.FORMAT_SHORT); // for a shorter day, eg Thu instead of Thurs
		var dateStr;
		dateStr = Lang.format("$1$ $2$$3$", [GetShortDayNameFromNumber(infoShort.day_of_week), info.month, info.day]);
		
		//	dateStartYBatteryAndDate = 200;
		try {
			// Code to execute
		//	if(gStrDeviceName.equals("Forerunner235")) {
		//		dateStartYBatteryAndDate = dateStartYBatteryAndDate + 4;
		//	}
			dc.drawText(dc.getWidth()-56, intDateStartYBatteryAndDate+27, Gfx.FONT_AUX1, dateStr , Gfx.TEXT_JUSTIFY_RIGHT);
		} catch( ex ) {
		// Code to catch all execeptions
			System.println("exception is 76 : " + ex.getErrorMessage());
		}
		

	} // end function DrawCurrentDate


	function DrawHeartRateAndBodyBattery(dc, intXForHR, intYForTime) {
			//  ==================================================
		//  draw  heart rate
		//  ==================================================
		// just beneath version, print heart rate
		var intYForHR = intYForTime;// 33;
		
		// get body battery if available
	     gIntYForBodyBattery = intYForTime+17;
		 var gIntXForBodyBattery = intXForHR-5;
		var dblBodyBatteryNumber = 0.0;
		dblBodyBatteryNumber = getBodyBatteryPercentAndSetColours();
		//var intDiffDesiredAndActualBodyBattery = gintDesiredBodyBattery - dblBodyBatteryNumber;
		//var strDiffInBodyBattery = intDiffDesiredAndActualBodyBattery;

		if(gintDesiredBodyBattery<0 ) {
			gintDesiredBodyBattery= 0;
		}
		if (dblBodyBatteryNumber!=0.0) {
			dc.setColor(gStrBBFontColour, gStrBBBackColour);
			dc.drawText(gIntXForBodyBattery+7,gIntYForBodyBattery , Gfx.FONT_SYSTEM_NUMBER_MILD, "" + dblBodyBatteryNumber.format("%.0f") , Gfx.TEXT_JUSTIFY_CENTER); //+ "(" + gintDesiredBodyBattery.format("%.0f") + ")"
			dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
		}	else {
			dc.drawText(gIntXForBodyBattery, gIntYForBodyBattery, Gfx.FONT_TINY, "? (" + gintDesiredBodyBattery.format("%.0f") + ")" , Gfx.TEXT_JUSTIFY_RIGHT);
		}
		// also print the expected body battery at this time
		
		
		
		// get a HeartRateIterator object; oldest sample first
		var intHeartRate = 0; 
		intHeartRate = getHeartRateAndSetColours(); //set gStrHRBackColor and gStrHRFontColor;
		if (intHeartRate != 0){
		
			dc.setColor(gStrHRFontColour,gStrHRBackColour);
			dc.drawText(intXForHR, intYForHR, Gfx.FONT_TINY, "" + intHeartRate, Gfx.TEXT_JUSTIFY_CENTER);
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		} //  print  heart  rate if not zerro

	
		
		// ====================end draw bb ===============================

	} // end function drawHeartRateAndBodyBattery

	function DrawWeeksMovementOrQuotesOrHourlySteps(dc, hour, minute, second ) {

			  // dc.drawText(dc.getWidth()-50, 150, Gfx.FONT_TINY, strVersion, Gfx.TEXT_JUSTIFY_RIGHT);
	    // dc.drawText(dc.getWidth()-50, 200, Gfx.FONT_MEDIUM, strVersion, Gfx.TEXT_JUSTIFY_RIGHT);
	     dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		// =====================================================================	     
	    // Get and draw the main quote on the screen 
		// =====================================================================
		// if the move bar is cleared, then buzz
		// if the hour is 11am or 4pm show our weekly stat
		//System.println("hour is : " + hour); 
		//System.println("min is : " + minute); 
		// 24/2 removed hour criteria here ((hour == 7)||(hour == 12) || (hour ==16) ||

		if (hour == 1 && minute == 1) {
			// clear days' steps
			ClearHourlySteps();

		}

		// atk temp only REMOVE 1/1/2025
		//if (hour == 18 && minute == 17) {			ClearHourlySteps();		}


		 if (minute == 59 && hour > 8 && hour < 23 && hour % 2 != 0) {
			// eg at 9:59, 11:59 etc
			SaveHourlyAnd2HourlySteps();
		 }

		//if (  (minute > 10 && minute < 20)|| ( minute > 40 && minute < 45) ) {
		if (minute % 4 == 0 ) {
			DrawCurrentHourAndLastHourSteps(dc, hour);
		} else if (minute % 3 == 0) {
			// show weeks movement history
			 DrawWeeksMovementHistory(dc);
			System.println("do weeks movement");
		} else if (minute % 2 == 0) {

				// draw hourly steps for day
				Draw2HourlyStepsForDay(dc);
		
		} else {
			
			// only want to redraw quote every hour or so???? Dn't want to change every second
			//var hourMod2 = hour % 2;
			// only change quote every odd hour and if the minute is 0 
			// so change quote every 2 hours!
			if (  ((minute == 31) || (minute == 0)) && (second <= 10)) {
				SetNewQuote();
				GetQuoteSizeAndDraw(dc);
		}

			DrawQuote(dc);
		
				
		} // end if hour - 7	  

	} // end functin draw weeks movement or quotest

	function ClearHourlySteps() {
		//  clear both 2 hour and 1 hour
		var intHour = 0;
		var strLabel = "";

		var strEndOfLabelHours = "";
		var strLabel2 = "";
		for (intHour = 6; intHour<23; intHour+=2) {
			strEndOfLabelHours = "" + intHour + "to" + (intHour+2);
			strLabel = "StepsSavedFor" + strEndOfLabelHours;
			strLabel2 = "TotalStepsSavedFor" + strEndOfLabelHours;
			Application.Storage.setValue(strLabel, 0);
		    Application.Storage.setValue(strLabel2, 0);

		} // end for

		for (intHour = 6; intHour<23; intHour++) {
			strEndOfLabelHours = "" + intHour + "to" + (intHour+1);
			strLabel = "StepsSavedFor" + strEndOfLabelHours;
			strLabel2 = "TotalStepsSavedFor" + strEndOfLabelHours;
			Application.Storage.setValue(strLabel, 0);
		    Application.Storage.setValue(strLabel2, 0);
		} // end for

	} // clear ak save of hourly steps


	function DrawCurrentHourAndLastHourSteps(dc, intCurrentHour) {
			dc.drawText(10, 30, Gfx.FONT_SYSTEM_TINY, "Steps recent", Gfx.TEXT_JUSTIFY_LEFT);

			var strEndOfLabelHours = "" + (intCurrentHour-1) + "to" + intCurrentHour;
			var strLabelLastHour = "StepsSavedFor" + strEndOfLabelHours;
			var intStepsForLastHour = Application.Storage.getValue(strLabelLastHour);
			if (intStepsForLastHour==null) {
				intStepsForLastHour =0;
			}

			var strEndOfLabel2HoursAgo = "" + (intCurrentHour-2) + "to" + (intCurrentHour-1);
			var strLabel2HoursAgo = "StepsSavedFor" + strEndOfLabel2HoursAgo;
			var intStepsFor2HoursAgo = Application.Storage.getValue(strLabel2HoursAgo);
			if (intStepsFor2HoursAgo==null) {
				intStepsFor2HoursAgo =0;
			}

			var strLabelLastHourTotal = "TotalStepsSavedFor" + strEndOfLabelHours;
			var intTotalStepsAtLastHour = Application.Storage.getValue(strLabelLastHourTotal);
			if (intTotalStepsAtLastHour==null) {
				intTotalStepsAtLastHour = 0;
			}

			var	  intStepsTotalRightNow = 0;
	    	if ( ActivityMonitor.getInfo().steps != null) {
	   	 		intStepsTotalRightNow =  ActivityMonitor.getInfo().steps;
	    	}
			var intStepsThisHour = intStepsTotalRightNow - intTotalStepsAtLastHour;
			var intX = 20;
			var intY = 50;
			var intYSizeAdjust =17;
			

			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
		    dc.drawText(intX, intY+1*intYSizeAdjust, Gfx.FONT_TINY, "This Hour: " , Gfx.TEXT_JUSTIFY_LEFT);
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
			dc.drawText(intX+125, intY+1*intYSizeAdjust, Gfx.FONT_TINY, intStepsThisHour, Gfx.TEXT_JUSTIFY_RIGHT);


			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
		    dc.drawText(intX, intY+2*intYSizeAdjust, Gfx.FONT_TINY, "Last Hour: " , Gfx.TEXT_JUSTIFY_LEFT);
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
			dc.drawText(intX+125, intY+2*intYSizeAdjust, Gfx.FONT_TINY, intStepsForLastHour, Gfx.TEXT_JUSTIFY_RIGHT);

			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
		    dc.drawText(intX, intY+3*intYSizeAdjust, Gfx.FONT_TINY, "2 Hours: " , Gfx.TEXT_JUSTIFY_LEFT);
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
			dc.drawText(intX+125, intY+3*intYSizeAdjust, Gfx.FONT_TINY, intStepsFor2HoursAgo, Gfx.TEXT_JUSTIFY_RIGHT);


	} // end function draw current hour and last hour steps


	function Draw2HourlyStepsForDay (dc) {

		// get all the hours and print them
		//eg StepsSavedFor18to20
		var intHour = 0;
		var strLabel = "";
		var intStepsFor2Hours = 0;
		var strEndOfLabelHours = "";
		dc.drawText(10, 30, Gfx.FONT_SYSTEM_TINY, "Steps / 2 hours", Gfx.TEXT_JUSTIFY_LEFT);
		var intLineNumber=0;
		var intX = 20;
		var strPrintLabel = "";
		
		for (intHour = 6; intHour<22; intHour+=2) {
			intLineNumber = intLineNumber + 1;
			strEndOfLabelHours = "" + intHour + "to" + (intHour+2);
			strLabel = "StepsSavedFor" + strEndOfLabelHours;
			intStepsFor2Hours = Application.Storage.getValue(strLabel);

			if (strEndOfLabelHours.length()==4) {
				strEndOfLabelHours = "06to08";
			}

			if (strEndOfLabelHours.length()== 5) {
				strEndOfLabelHours="08to10" ; // pad for formatting
			}
			if(intStepsFor2Hours==null) {
				intStepsFor2Hours = 0;
			}
			if (intStepsFor2Hours>0) {
				intStepsFor2Hours=intStepsFor2Hours; //yays
			}
			if (intHour == 14) {
				intX = 96;
				intLineNumber = 1;
			}
			strPrintLabel = strEndOfLabelHours.substring(0,2);
			dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
		    dc.drawText(intX, 30+intLineNumber*18, Gfx.FONT_SYSTEM_TINY, strPrintLabel , Gfx.TEXT_JUSTIFY_LEFT);
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
			dc.drawText(intX+60, 30+intLineNumber*18, Gfx.FONT_SYSTEM_TINY, intStepsFor2Hours, Gfx.TEXT_JUSTIFY_RIGHT);
			System.println("HourlySteps: Get and print for hour " + strLabel + " with value" + intStepsFor2Hours); 

		}

	} // draw 2 hourly steps

	function SaveHourlyAnd2HourlySteps() {
			// try to get an idea of how much I move each hour or two
			// would be called once every 2 hours say, 
			// eg at 9:59am, 11:59am, 13:59, 15:59, 17:59. 
			// based on time, calculate how many steps made since last save
			
			var	    strSteps = 0;
	    	if ( ActivityMonitor.getInfo().steps != null) {
	   	 		strSteps =  ActivityMonitor.getInfo().steps;
	    	}
			var strLabelOfLastStepsRecorded = "StepsSavedFor8to10";
			var strLabelOfLastStepsRecordedHourly = "StepsSavedFor8to9"; //eg 
			var intCurrentHourOfDay = getHourOfDay();
		
			strLabelOfLastStepsRecorded = "StepsSavedFor" + (intCurrentHourOfDay-1) +"to" + (intCurrentHourOfDay+1);
			strLabelOfLastStepsRecordedHourly = "StepsSavedFor" + (intCurrentHourOfDay-1) + "to" + (intCurrentHourOfDay);
			var strLabelOfLastStepsRecordedTotal = "TotalStepsSavedFor" + (intCurrentHourOfDay-3) + "to" + (intCurrentHourOfDay-1);
			var strLabelOfLastStepsRecordedTotalHourly = "TotalStepsSavedFor" + (intCurrentHourOfDay-2) + "to" + (intCurrentHourOfDay-1);

			System.println("HourlySteps: Hour is " + intCurrentHourOfDay); //e.g. 2 or 1)
			System.println("HourlySteps: Save with label " + strLabelOfLastStepsRecorded); 
			var strLabelForThisSteps = "StepsSavedFor" + (intCurrentHourOfDay-1) + "to" + (intCurrentHourOfDay+1);
			var strLabelForThisStepsHourly = "StepsSavedFor" + (intCurrentHourOfDay) + "to" + (intCurrentHourOfDay+1);

			
			var intTotalStepsRecordedLastTime = Application.Storage.getValue(strLabelOfLastStepsRecordedTotal);
			if (intTotalStepsRecordedLastTime == null) {
				intTotalStepsRecordedLastTime = 0;
			}

			var intTotalStepsRecordedLastTimeHourly = Application.Storage.getValue(strLabelOfLastStepsRecordedTotalHourly);
			if (intTotalStepsRecordedLastTimeHourly == null) {
				intTotalStepsRecordedLastTimeHourly = 0;
			}

			var strLabelOfThisStepsRecordedTotal = "TotalStepsSavedFor" + (intCurrentHourOfDay-1) + "to" + (intCurrentHourOfDay+1);
			var strLabelOfThisStepsRecordedTotalHourly = "TotalStepsSavedFor" + (intCurrentHourOfDay) + "to" + (intCurrentHourOfDay+1);

			// record total steps at moment
			Application.Storage.setValue(strLabelOfThisStepsRecordedTotal, strSteps);
			Application.Storage.setValue(strLabelOfThisStepsRecordedTotalHourly, strSteps);

			var intCurrent2HoursSteps = strSteps  - intTotalStepsRecordedLastTime;
			var intCurrent1HourSteps = strSteps  - intTotalStepsRecordedLastTimeHourly;

			Application.Storage.setValue(strLabelForThisSteps, intCurrent2HoursSteps);
			Application.Storage.setValue(strLabelForThisStepsHourly, intCurrent1HourSteps);

			System.println("HourlySteps: This steps to save " + intCurrent2HoursSteps); 
			System.println("HourlySteps: Total Steps " + strSteps); 
			System.println("HourlyStepsTotal: Labels are " + strLabelForThisSteps + " " + intCurrent2HoursSteps  + " and " + strLabelOfThisStepsRecordedTotal + " " + strSteps); 



	} // end Save2HourlySteps

	function DrawWatchBatteryStats(dc, intXBodyBattery, intTimeY) {


	    dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_BLACK); // just in case we changed it 
	
		// =====================================================================	    
	    // Put some battery stats	    
		// =====================================================================	    
		var myStats = System.getSystemStats();
		//System.println(myStats.battery);
		//System.println(myStats.totalMemory);
		var strBatteryPercent = Lang.format("$1$",[myStats.battery.format("%02d")])+ "%";	    
		
		var batteryX = intXBodyBattery-15;
		var batteryHeight = 9; // was 14
		
		var batteryWidth = 18;
	
		var batteryY = intTimeY+55; //+4
		//var intNippleMid = batteryHeight/2;
		var intNippleHeight = batteryHeight/2;
		var intNippleY = batteryY + intNippleHeight/2;
 		var textColor="";
 		var lineColor="";
		var backColor="";
		var intBatteryWarning = 10;
		var intBatterySevere = 5;
		// set the colour for the battery if it is low what about making it red if the battery is less than 15%?
		if (myStats.battery < intBatterySevere ) { 	
		 	// make the battery bolder, ie thicker 
		 	System.println("Drawing red and thicker");
		 	textColor = Gfx.COLOR_WHITE;
		 	lineColor = Gfx.COLOR_WHITE;
		 	backColor = Gfx.COLOR_WHITE;
		 	//dc.drawRoundedRectangle(batteryX, batteryY, batteryWidth, batteryHeight,1 );
		 } else if ( myStats.battery < intBatteryWarning  ) {		
		 	textColor = Gfx.COLOR_WHITE;
		 	lineColor = Gfx.COLOR_LT_GRAY; //should be yello
		 	backColor = Gfx.COLOR_DK_GRAY;
		 } else {
			textColor = Gfx.COLOR_WHITE;
		 	lineColor = Gfx.COLOR_WHITE;
		 	backColor = Gfx.COLOR_WHITE;
		 }

		//if battery is charging, set an orange dot or something - a z
		// battery charging stas only availabe after?  version 3
		System.println(gNumAPIMajorVersion); //e.g. 2 or 1)
		if (gNumAPIMajorVersion>= 3) {
		
			if (!myStats.charging) {
			dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);
			dc.drawText(batteryX+3, batteryY-9 ,  Gfx.FONT_XTINY, "z" , Gfx.TEXT_JUSTIFY_LEFT);
			} // end if chargin
		} // if version > 3
		 
// Gfx.getVectorFont("#BionicBold:12,Roboto");
         dc.setColor(textColor,backColor);		 	
	    // dc.drawText(batteryX, 
		// batteryY ,
		 //  Gfx.FONT_XTINY,
		 //strBatteryPercent,
		//  Gfx.TEXT_JUSTIFY_LEFT);
	     //draw a box around the battery that looks like a battery?	     
	     
	     dc.setColor(lineColor,textColor); 	
	     dc.drawRoundedRectangle(batteryX-2, batteryY, batteryWidth, batteryHeight,1 );	 
		 var i =0;
		 var intBatteryPercent = strBatteryPercent.toNumber();		 
		 for (i=1;i<intBatteryPercent/5;i++) {
			dc.fillRectangle(batteryX+i, batteryY, 1, batteryHeight );	 
		 }      	
	     // draw the battery nipple - just the nipple     
		 //dc.drawRoundedRectangle(x, y, width, height, radius)
	   //  dc.drawRoundedRectangle(batteryX-5, batteryY+9, 4, 12, 2);
		   dc.drawRoundedRectangle(batteryX-5, intNippleY, 4, intNippleHeight, 2);
		 
	}  // end function DrawWatchBatteryStats

	function DrawTimeAndVersion(dc, intXForTime, intYForTime, clockTime, hour, minute, second) {

		
        // Get and show the current time
        
       
	
		// =====================================================================            
		// Draw the clock / time     , version and heart rate and body battery
		// =====================================================================

		//draw hour in the middle left justified
		
		
	    dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
	    dc.drawText(intXForTime, intYForTime, Gfx.FONT_NUMBER_MILD, hour.toString()+ ": ", Gfx.TEXT_JUSTIFY_RIGHT);
	    //was intX + 10

		// draw minutes a bit darker from middle, right justified
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
	    dc.drawText(intXForTime-5, intYForTime, Gfx.FONT_NUMBER_MILD, Lang.format("$1$", [clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);	    
	    
		// ======================================================================================
		// draw seconds
		// draw seconds in a smaller font from middle plus two chars size text justify left
		intYForTime = intYForTime;
	
		dc.drawText(intXForTime+20, intYForTime, Gfx.FONT_XTINY, Lang.format("$1$", [clockTime.sec.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);	    
		dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
		var intYForVersion = 20;

	     // and the version	     
	     //dc.drawText(dc.getWidth()-50, 1, Gfx.FONT_SYSTEM_XTINY, strVersion, Gfx.TEXT_JUSTIFY_RIGHT);
	     // draw multiple versions to see what size we want
	     //dc.drawText(dc.getWidth()-50, 50, Gfx.FONT_SYSTEM_NUMBER_MILD, strVersion, Gfx.TEXT_JUSTIFY_RIGHT);
	    dc.drawText(10, intYForVersion, $.customFontSmall, strVersion, Gfx.TEXT_JUSTIFY_LEFT);

	}

	function getBodyBatteryPercentAndSetColours() {
		//trying to change this to minutes.. but failing9:09am 28 March 2023
		var dblBodyBatteryPercent = 0.0;
		var objABodyBattery=null;
		var bbIterator = getBodyBatteryIterator();
		if (bbIterator!=null)  {
		 objABodyBattery = bbIterator.next();                         // get the body battery data
		}
		if (objABodyBattery != null) {
			System.println("Sample: " + objABodyBattery.data);           // print the current sample
			dblBodyBatteryPercent = objABodyBattery.data;
		} else {
						System.println("getBodyBatteryPercentAndSetColours: objABodyBattery is NULL!!!!");           // print the current sample

		}

		//========set colors based on time of day AND Percent ================
		if (dblBodyBatteryPercent == null) {
			dblBodyBatteryPercent = 0.0;
		}
		var intCurrentHourOfDay = getHourOfDay();
		var intCurrentMinutes = getMinutesOfHour() ;// eg if time is 7:45, return 45 // 1-60

		
		var dblAwakeHours = gIntFinishOfDayHour - gIntStartOfDayHour;
		var intTotalMinutesAwake = dblAwakeHours *60;
			//var intMinutesExpended = // (intFinishTime - intCurrentTime) 
			//var intMinutesLefInDay = //intMinutesInDay - intMinutesExpended   //intMinutesLeftInDay - 

		//var momentNow = new Time.Moment(Time.today().value());
		//var timeForSecondsAwake = new Time.Duration(Gregorian.SECONDS_PER_HOUR*dblAwakeHours);
			//var tomorrow = today.add(oneDay);

			//var duration1 = momentNow.subtract(tomorrow);
			//var duration2 = tomorrow.subtract(today);

			//System.println(duration1.value()); // 86400, or one day
			//System.println(duration2.value()); // 86400, or one day

		var intHoursLeftInDay = gIntFinishOfDayHour-intCurrentHourOfDay;
			
			// better to compare minutes than hours YAY
		var intMinutesLeftInDay = intHoursLeftInDay*60 -(60- intCurrentMinutes);
		var dblPercentOfDayLeftByMinutes =  100*(intMinutesLeftInDay.toDouble()/intTotalMinutesAwake.toDouble());
		if (intCurrentHourOfDay>5 && intCurrentHourOfDay <= 22) {
		   gintDesiredBodyBattery = dblPercentOfDayLeftByMinutes;
		} else {
			gintDesiredBodyBattery = 0;

		}
// test - set dblBodyBatteryNumber to various numbers
//	dblBodyBatteryPercent =30;

		if(dblBodyBatteryPercent!=0.0){

			// try to get some equation to check if percentage of body battery is > percentage of day left
			// assume day starts at 6am and finishes at 10pm or 22:00. 
	
			//var dblPercentOfDayLeft =  100*(intHoursLeftInDay.toDouble()/dblAwakeHours.toDouble());
			var intBBTolerance = 10;
			var intDiffDayLeftAndBB = (dblBodyBatteryPercent)-dblPercentOfDayLeftByMinutes;

			// lets add a pink if in tolerance
			

			if( intDiffDayLeftAndBB > 0) { // ie body battery % > day left % . Very good
				 gStrBBBackColour=Gfx.COLOR_BLACK;
				 gStrBBFontColour=Gfx.COLOR_GREEN;	
			} else if ((intDiffDayLeftAndBB + intBBTolerance) > 0) {
				// eg day left=40 and we are 35. 
				 gStrBBBackColour=Gfx.COLOR_BLACK;
				 gStrBBFontColour=Gfx.COLOR_YELLOW; // pink is easier to read than orange. 
			} else if (intDiffDayLeftAndBB > -20)  {
				// eg say we are 10-20 below day left, eg day left - 40 we are 25 
				 gStrBBBackColour=Gfx.COLOR_BLACK;
				 gStrBBFontColour=Gfx.COLOR_PINK;	
			} else {
				// really bad here we are more than 20 below!@!!
				 gStrBBBackColour=Gfx.COLOR_LT_GRAY;
				 gStrBBFontColour=Gfx.COLOR_RED;	

			} // will add later, if less than say 10% less, then show orange or yellow or blue
		// ====================end draw bb ===============================
		} // end if 0
		return dblBodyBatteryPercent;
	} // end function get body battery percent and set colours


	function getMinutesOfHour () {
		// eg given 7:45, return 45. should always return between 0 and 59. 
		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		
		var intMinutes = today.min;
		return intMinutes;
		//System.println(dateString); // e.g. "16:28:32 Wed 1 Mar 2017"
	}
	function getHourOfDay () {

		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		/*var dateString = Lang.format(
 		   "$1$:$2$:$3$ $4$ $5$ $6$ $7$",
			[
				today.hour,
				today.min,
				today.sec,
				today.day_of_week,
				today.day,
				today.month,
				today.year
			]
		);*/
		var intHour = today.hour;
		return intHour;
		//System.println(dateString); // e.g. "16:28:32 Wed 1 Mar 2017"
	}


    function getHeartRateAndSetColours() {

		var intHeartRate =0; // default to 0

		intHeartRate = Activity.getActivityInfo().currentHeartRate;


		if (intHeartRate == null ) { 
			intHeartRate = 0;
			System.println("getHeartRate: heart rate from getActivityInfo().currentHeartRate was null" );  
		}
		if (intHeartRate == 0) {
			//TRY ANOTHER WAY :)
		
			var blHasHR=(ActivityMonitor has :HeartRateIterator) ? true : false;
			if (blHasHR==true) {
				var hrIterator = ActivityMonitor.getHeartRateHistory(null, true);
				System.println("getHeartRate: we have a heart rate iterator" );      
			//	var previous = hrIterator.next();                                   // get the previous HR
			//	var lastSampleTime = null;        
												// get the last
				var heartRateObject = hrIterator.next();
				if (null != heartRateObject) { 
					System.println("getHeartRate: we have a heart rate objecdt" );                                                // null check
					if (heartRateObject.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
						System.println("getHeartRate: we have a valid heart rate object" );      
						System.println("Heart Rate is : " + heartRateObject.heartRate);      // print the current sample
						intHeartRate =  heartRateObject.heartRate;
					}
				}
			} // if has hr
		} // IF HEART RATE IS 0 TRY ANOTHER WAY
	
		if (intHeartRate > 110) {
			gStrHRBackColour = Gfx.COLOR_WHITE;
			gStrHRFontColour = Gfx.COLOR_BLACK;
		} else if (intHeartRate >= 100) {
			gStrHRBackColour = Gfx.COLOR_WHITE;
			gStrHRFontColour = Gfx.COLOR_BLACK;
		} else if (intHeartRate >= 80) {
			gStrHRBackColour = Gfx.COLOR_BLACK;
			gStrHRFontColour = Gfx.COLOR_LT_GRAY;
		} else if (intHeartRate > 30 && intHeartRate <60) {
			gStrHRBackColour = Gfx.COLOR_BLACK;
			gStrHRFontColour = Gfx.COLOR_WHITE;
		} else {
			gStrHRBackColour = Gfx.COLOR_BLACK;
			gStrHRFontColour = Gfx.COLOR_WHITE;
		}
		 // heartrate = -0


		return intHeartRate;

	} // end function getHeartRate

	function SetNewQuote() {
		gStrCurrentQuote = getRandomQuote();
	}
	
	function getBodyBatteryIterator() {

	if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory)) {
          // Set up the method with parameters
          return Toybox.SensorHistory.getBodyBatteryHistory({});
      } else {
		System.print("getBodyBatteryIterator: Looks like we coudn't get body battery history from toybox. NOT GOOD. ");
	  }
      return null;
  }
	

	function GetQuoteSizeAndDraw(dc) {  // no longer used?
	
		var strQuote = getRandomQuote();
		drawTextOverMultiLines( dc, strQuote );
	
	} // end GetQouteSizeAndDraw
	
	function DrawQuote(dc) {
		drawTextOverMultiLines( dc, gStrCurrentQuote );
	}
	
	// ================================================================================================
	// will draw 2k steps 2km 
	// I will add a comment eg 1km stps over 2km - Not moving much
	// etc
	// Maybe keep a counter and if not walking for 2 days and those days arent sat and sunday ask if you are tired
	// ================================================================================================
	function DrawWeeksMovementHistory(dc) {

			
			var intNumberOfDaysHistoryToShow = 3; // does this also change the total count? ie only use this nyumber of days?
			var intHeightOfText = 17; //was 21 // is this the height of the font?
			
			var dailyHistoryArr = ActivityMonitor.getHistory(); //gets 7 days history
			/* System.println("Draw previous history") print the previous sample
			   System.println("history array size is " + dailyHistoryArr.size() );  // print the previous sample
			  */  
			// GEt the current day eg Monday/Tuesday/Wednessay to work out what days we have			
			var infoDateTimeNow = Gregorian.info(Time.now(), Time.FORMAT_SHORT); // 6= friday
			 System.println(infoDateTimeNow.day_of_week);
			 var intDayOfWeekToday = infoDateTimeNow.day_of_week; 
			 // eg 6 = friday

			System.println("Today is " + 	GetShortDayNameFromNumber(intDayOfWeekToday));
			var intHeightForStatsForWeek = intHeightOfText*(intNumberOfDaysHistoryToShow); // // + 1 for the title fo Week. was 100 22 july 2022						
			var intYForStats = 100; //dc.getHeight() - intHeightForStatsForWeek  +20 ; //  added 2 cause it was too high

			
			// dc.getWidth()/2;
			var strDayOfReading = "";
			var dblDistanceInKmsForDay = 0.0;			    
			var strComment = "";
			var strText = "";
			var dblTotalKmsForWeek = 0.0;
			
	    	var intXLocationForDay = 5 ;
			var intXLocationForKms = 50 ; 
			
			var fontSize = Gfx.FONT_XTINY; //smallest font size;
			try {
			// loop through the 7 day history on the watch			    
			for( var i = 0; i < dailyHistoryArr.size(); i++ ) { 
				if( i < intNumberOfDaysHistoryToShow ) { // i only want to show x days history plus today				
				    // System.println("Previous: " + i + " day" +  dailyHistoryArr[i].steps + " steps / ");  // print the previous sample
				    // System.println("Previous: " + dailyHistoryArr[i].distance + " d");  // print the previous sample
						
						strDayOfReading = GetShortDayNameFromNumber(intDayOfWeekToday-1-i); // will accept negative numbers and convert to day of week. 
						dblDistanceInKmsForDay = GetKMMovedDbl(dailyHistoryArr[i].distance);
						dblTotalKmsForWeek = dblTotalKmsForWeek + dblDistanceInKmsForDay;
						if (strDayOfReading.equals("Sun") ) {
							strComment = " / Wknd";
						} else if (dblDistanceInKmsForDay > 15) {
							strComment = "/ :D :D Hooray!";
							} else if (dblDistanceInKmsForDay > 14) {
							strComment = "/ Great!";										    			
						} else if (dblDistanceInKmsForDay > 13) {
							strComment = "/ Fantastic!";										    			
						} else if (dblDistanceInKmsForDay > 12) {
							strComment = "/ Excellent!";										    			
						} else if (dblDistanceInKmsForDay > 11) {
							strComment = "/ Delightful :)";										    			
						} else if (dblDistanceInKmsForDay > 10) {
							strComment = "/ Cheering";
						} else if (dblDistanceInKmsForDay > 9) {
							strComment = "/ Beauty!";										    			
						} else if (dblDistanceInKmsForDay > 8) {
							strComment = "/ Awesome";				
						} else if (dblDistanceInKmsForDay > 7) {
							strComment = "/ Walk boy";									
						} else if (dblDistanceInKmsForDay > 6) {
							strComment = "/ Meh";								
						} else if (dblDistanceInKmsForDay > 5) {
							strComment = "/ Slowish?";											    	
						} else if (dblDistanceInKmsForDay < 5) {
							strComment = "/ Quiet";
																		
							
						} else {
						strComment = "";
						}
						

						strText = dblDistanceInKmsForDay.format("%0.1f") + " kms " + strComment;
						
						dc.drawText(intXLocationForDay, intYForStats-(intHeightOfText*i), fontSize,
						strDayOfReading, Gfx.TEXT_JUSTIFY_LEFT);
						dc.drawText(intXLocationForKms, intYForStats-(intHeightOfText*i), fontSize,
						strText , Gfx.TEXT_JUSTIFY_LEFT);
						}
						
				} // end for loop

				// ==================================================
				// Draw total for week at top. Maybe change colours. 
				// ==================================================
				// and add a smiley face
				// add todays total to weeks total

				dblTotalKmsForWeek = dblTotalKmsForWeek + GetTodaysDistanceKMDbl();

				var strPostTotal = "";
				if (dblTotalKmsForWeek>45)  {
					dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_WHITE);
					strPostTotal ="! :D ";
				} else if (dblTotalKmsForWeek>40) {
					dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_LT_GRAY);
					strPostTotal = "!!!";
				} else if (dblTotalKmsForWeek>35) {
					strPostTotal = "!!";
					dc.setColor(Gfx.COLOR_PINK, Gfx.COLOR_BLACK);
				} else if (dblTotalKmsForWeek>30) {
					dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_BLACK);
				} else if (dblTotalKmsForWeek>25) {
					dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);
				}
				

				dc.drawText(intXLocationForDay, intYForStats-(intHeightOfText*(intNumberOfDaysHistoryToShow)), fontSize, "Week ", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(intXLocationForKms+ 15, intYForStats-(intHeightOfText*(intNumberOfDaysHistoryToShow)), fontSize,
				dblTotalKmsForWeek.format("%d") + " kms" + strPostTotal , Gfx.TEXT_JUSTIFY_LEFT);
			

				// set colour back
				dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
			} catch (exception) {
				System.println("catch");
			}

			finally
			{
				System.println("finally");
			}
						

	} // DrawWeeksMovementHistory
	

		function GetShortDayNameFromNumber(intNumber) {
		// eg given 5, return Thursday
		// given 4, return Wednesday
		// given 3 - Tue, 2 = Mon, 1 = Sun, 0 = Sat, -1 = Friday, -2 = Thu, -3 = Wed
		if (intNumber<0) {
		  intNumber = intNumber+7;
		}
		var strDayNameShort = "NoIdea";
		if (intNumber == 0) {
		  strDayNameShort = "Sat";
		} else if (intNumber == 1) {
		  strDayNameShort = "Sun";
		} else if (intNumber == 2) {
		  strDayNameShort = "Mon";
		} else if (intNumber == 3) {
		  strDayNameShort = "Tue";
		} else if (intNumber == 4) {
		  strDayNameShort = "Wed";
		} else if (intNumber == 5) {
		  strDayNameShort = "Thu";
		} else if (intNumber == 6) {
		  strDayNameShort = "Fri";
		} else if (intNumber == 7) {
		  strDayNameShort = "Sat";
		} 
		return strDayNameShort;
	} //GetShortName

	function DrawKMTravelledAndMoveBar(dc) {
	// draw how far we have gone today and show move bar if we haven[t moved much
		var xForStepsAndKms = 50 ; //10
	    var yForStepsKMAndMoveNumber = dc.getHeight()-47; // was 53
		
	    var strKMMoved = 0;
		//var dblKMMoved = GetTodaysDistanceKMDbl();
	    strKMMoved = GetTodaysDistanceKMStr();
		var	    strSteps = 0;
	    if ( ActivityMonitor.getInfo().steps != null) {
	   	 strSteps =  ActivityMonitor.getInfo().steps;
	    }
	    
	   // does not work on forerunner 235! it's not a cq2 device! var strActiveMinutes = ActivityMonitor.getInfo().activeMinutesDay; 
	    
	    var strStepsAndKmsWords =   "k stps/" + strKMMoved + "kms";
		var strStepsNumber = convertToThousandsShorthand(strSteps);

		var intWidthForTotals = dc.getWidth()-10;
		var intHeightForTotals = dc.getHeight()/5;


		// draw numbers in larger text for instinct

		dc.drawText(xForStepsAndKms, yForStepsKMAndMoveNumber-5, Gfx.FONT_NUMBER_MILD, strStepsNumber, Gfx.TEXT_JUSTIFY_RIGHT);

	    dc.drawText(
				xForStepsAndKms+2, 
				yForStepsKMAndMoveNumber+5, 
				Gfx.FONT_SMALL, 
				Graphics.fitTextToArea(strStepsAndKmsWords, Gfx.FONT_SMALL, intWidthForTotals, intHeightForTotals, true), 
				Gfx.TEXT_JUSTIFY_LEFT);
	    
   	    // =====================================================================
	    // add move bar - red
	    // =====================================================================
	   
	    var intMoveBarLevelCurrent = ActivityMonitor.getInfo().moveBarLevel;	    	     
	     if (gIntLastMoveBarLevel > 0) {
		     if (ActivityMonitor.getInfo().moveBarLevel==0) {
    	     	gIntNumberOfMovedHours=gIntNumberOfMovedHours+1 ; // might need to reset this each day
		     }
		   }
	      gIntLastMoveBarLevel=intMoveBarLevelCurrent;
	      Sys.println("-------------------- Move bar level ------------------------------");
	      Sys.println("Move bar Last level = " + gIntLastMoveBarLevel + ", current level = " + intMoveBarLevelCurrent);
	      Sys.println("Move bar - Number of hours moved = " + gIntNumberOfMovedHours);
	      Sys.println("-------------------- Move bar level ------------------------------");
	    var moveBarLength = ActivityMonitor.getInfo().moveBarLevel*25;	    	    
	   // dc.drawLine(40, startY, 40+moveBarLength, startY);
	   yForStepsKMAndMoveNumber = yForStepsKMAndMoveNumber+10;
	   var myMoveBarLevel = moveBarLength/25;
	    dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_WHITE); // just in case we changed it 	 
		var intRectangleX = 10;
		var intRectangleY = 0;
		var intRectangleLength = 0;
		var intRectangleHeight = 0;
		var i=0;
		for ( i=1; i< myMoveBarLevel*10; i++) 
		{
			intRectangleX = 3 + i*3;
			intRectangleY = yForStepsKMAndMoveNumber-i*1;
			intRectangleLength = 1;
			intRectangleHeight = 1+i*1;
			 Sys.println("- Rectangle x=" + intRectangleX + ", y=" + intRectangleY + " l=" + 
			 intRectangleLength + " height=" + intRectangleHeight);

	      //dc.fillRectangle(intRectangleX, intRectangleY-1, intRectangleLength, intRectangleHeight);
	    // dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_BLACK); // just in case we changed it 
	     // and draw a thiker? bar to highliht 
	       dc.fillRectangle(intRectangleX, intRectangleY, intRectangleLength, intRectangleHeight);
		   
		}// end for 	
		

		 if (ActivityMonitor.getInfo().moveBarLevel > 0) {
		    dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_WHITE); // just in case we changed it 	     
		   // not enough room for the number! dc.drawText(startXForMoveBarValue-40+myMoveBarLevel*10, yForStepsKMAndMoveNumber-10- myMoveBarLevel*2, Gfx.FONT_SMALL,ActivityMonitor.getInfo().moveBarLevel , Gfx.TEXT_JUSTIFY_RIGHT);	    	    
	   }

	    
	 } // end drawkm travlled
	
function getRandomQuote() {
	
		// I'll change it to get teh quote based on the date. Otherwise it changes waaaay too much. 
		
		var arrQuotes =  new [7];		
		arrQuotes[0]=  "Run the race to the finish. Dean Karnazes";
		arrQuotes[1]=  "God      Loves       Me";
		arrQuotes[2]=  "I RUN THIS BODY";
		arrQuotes[3]=  "I'll be happy if running and I can grow old together. Haruki Murakami";
		arrQuotes[4]=  "Running! There's no activity happier, more exhilarating, more nourishing to the imagination. Oates";
		arrQuotes[5]=  "Running (and God) is my therapy.";
		arrQuotes[6]=  "Fitness starts now!";	
		
	//	var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		var r;	
		r = Mt.rand() % arrQuotes.size(); //Random number			
		//r = today.day_of_week-1; // get based on day of week,n ot random
		//Sys.println(r); //To check the result
		if(gBlDebug == true) {
		  r=4; // debug retun the long one to see what's going on. 
		}
		return arrQuotes[r]; 
			
	} // Get Random Quote

	function drawTextOverMultiLines( dc, strText ) {
	
	    if (strText=="") {
			//just for debug
			Sys.println("strText is blank for some reason - ! ");
		}
		// Choose a font size based on the length of the quote. 
		var myFont = ChooseFontBasedOnLengthAndSetColorFenix5(strText, dc);
		
		var rowHeight = $.gRowHeight; // check row height... do variables work? Globals?		
		//Sys.println(strText);
		var oneCharWidth=dc.getTextWidthInPixels("AbCdEfGhIj",myFont)/10;
		var intCharsPerLine= dc.getWidth()/oneCharWidth-2; // was -2 to make it look nicer ie not to edge, rmeoved by ak for fenix 5 to fit more
		
		if (gStrDeviceName.equals("Forerunner235")) {
			intCharsPerLine = intCharsPerLine +2;
		}
		
		var gYStartPositionForQuotes = 30; // starting y position
	
		if (strText.length() == "God      Loves       Me".length()) {

			Sys.println(strText);
			// just a line for debug
		}

	 	Sys.println("length is  " + strText.length() + " .Number of chars which can fit on line =" + intCharsPerLine);
		var fltNumberOfLinesNeeded = (strText.length()*1.00)/(intCharsPerLine-0)*1.00; //-2 is a fudge because God loves me is going on 3 lines but this returns 2~!!!!!
		var intNumberOfLinesNeeded = (fltNumberOfLinesNeeded + 0.9).toNumber(); //my strange roundUP function
		//Sys.println("number of lines needed = " + intNumberOfLinesNeeded);
		var blPrint = false;
	    intNumberOfLinesNeeded = PrintOrCountNumberOfLinesNeeded(dc, strText, intCharsPerLine, gYStartPositionForQuotes, myFont, blPrint);

		
		//Sys.println("intNumberOfLinesNeeded= "  + intNumberOfLinesNeeded + " yStartPosition is " + gYStartPositionForQuotes + " rowHeight is " + rowHeight);
		if (intNumberOfLinesNeeded == 1 ) {
		       gYStartPositionForQuotes = dc.getHeight()/2-rowHeight; //- put it in the middleish!
		   //Sys.println("1 lines exactly... put it in the middle!");
		
		} else if (intNumberOfLinesNeeded > 1 && intNumberOfLinesNeeded<2 ) {
		       gYStartPositionForQuotes = dc.getHeight()/2-rowHeight*1.2; //- put it in the middleish!
		   //  Sys.println("1 lines needed ... put it in the 2iddle!");
		
		} else if (intNumberOfLinesNeeded >= 2 && intNumberOfLinesNeeded < 3) {
		       gYStartPositionForQuotes = dc.getHeight()/2-rowHeight*1.5; //- put it in the middleish!
		   // Sys.println("2 lines... put it in the middle!");
		
		} else if (intNumberOfLinesNeeded >= 3 && intNumberOfLinesNeeded < 4) {
		       gYStartPositionForQuotes = dc.getHeight()/2-rowHeight*2.3; //- put it in the middleish! was 2.1
		      gYStartPositionForQuotes = dc.getHeight()/2-(rowHeight*intNumberOfLinesNeeded)*0.6;
			 // Sys.println("3 lines... put it in the middle!");
		
		} else  {
			gYStartPositionForQuotes = dc.getHeight()/2-(rowHeight*intNumberOfLinesNeeded)*0.6;
			//Sys.println("more than 3 lines and not less than 4 lines... put it in the middle!");
		}
		
		if (intCharsPerLine > strText.length() ) {
				// if we all fit on one line... 
		 gYStartPositionForQuotes = dc.getHeight()/2-rowHeight*0.8; //- put it in the middle!
		     //Sys.println("Only 1 line.. try to put it in themiddle");
		}
		
		Sys.println("gYStartPositionForQuotes is " + gYStartPositionForQuotes + " rowHeightXXX is " + rowHeight);

		if (gYStartPositionForQuotes < 25 ) { //we don't want to overwrite time
			gYStartPositionForQuotes = 25;
		}

		blPrint = true;
	    intNumberOfLinesNeeded = PrintOrCountNumberOfLinesNeeded(dc, strText, intCharsPerLine, gYStartPositionForQuotes, myFont, blPrint);

		
		
	} //drawTextOverMultiLines

	function PrintOrCountNumberOfLinesNeeded(dc, strText, intCharsPerLine, yStartPosition, myFont, blPrint) {
		
		var intLastSpaceLoc;
		//var intLocOfLastSpace=0;
		var intLinesNeeded=0;
		var intLenLeftToPrint = strText.length();
		// print out the words on multiple lines
		//Sys.println("Starting to get each line...");
		do {
		   
		   // find last " " before the width allowed.
		   intLinesNeeded = intLinesNeeded + 1;
		   intLastSpaceLoc = findLastSpaceBeforeLineLength( strText, intCharsPerLine );
//Sys.println("Last Space loc = " + intLastSpaceLoc);		   
		   if (intLastSpaceLoc == -1) {
		    	intLastSpaceLoc = intLenLeftToPrint;
		   }		   		   
		   var strPrintThis = strText.substring(0, intLastSpaceLoc); // need to fix this to find first " " before end
		   //intLocOfLastSpace = strPrintThis.find( 
		   strText = strText.substring(intLastSpaceLoc+1, strText.length());
		   intLenLeftToPrint = strText.length();
		   if (blPrint==true) {
		   	dc.drawText(gXForTextLoc,yStartPosition, myFont, strPrintThis, Gfx.TEXT_JUSTIFY_LEFT);
		   }
		   yStartPosition = yStartPosition + gRowHeight; 
		} while  (intLenLeftToPrint > intCharsPerLine );
		
		// draw anything left 
		
		if (strText.equals("")) {
				// what is this is blank.. i'll check
		} else {
			if (blPrint==true) {
				dc.drawText(gXForTextLoc,yStartPosition, myFont, strText, Gfx.TEXT_JUSTIFY_LEFT);
			}
			intLinesNeeded = intLinesNeeded + 1;
			
		}
		return intLinesNeeded;
	} // PrintOrCountNumberOfLinesNeeded

	function GetTodaysDistanceKMDbl() {
			//note nothing passed in
			// eg return 1.40423565
	    
	    var dblCentimetersMoved = ActivityMonitor.getInfo().distance;	 // centimeters moved    
	    return GetKMMovedDbl(dblCentimetersMoved);
	} //GetTodaysDistanceKMDbl

	function GetTodaysDistanceKMStr() {
		// eg return "1.3"
		return GetTodaysDistanceKMDbl().format("%0.1f");
	} // GetTodaysDistanceKMStr

		function convertToThousandsShorthand(aNumber) {
	    // eg convert 11250 to 11.2 // I'm not getting the .2 though am i.. I want it. 
	    var newNumber = aNumber / 1000.0;
		/*var justKMs = newNumber;
		var justKMsInMeters = justKMs *1000; eg 11000 
		var totalMinusFullKs = aNumber - justKMsInMeters; // eg 250.. but I just want 2
		var justExtraMeters = totalMinusFullKs/100; should give me 2. 
		var strKmsWithDotMeters = justKMs */

		var strNumber = newNumber.format("%0.1f");

	    System.println(strNumber);
	    return strNumber;
	} // convertToThousandsShorthand


	function findLastSpaceBeforeLineLength( strText, intMaxLineLength ) {


		// too slow on actual watch, just split
		
		
	 	var strLeftOfLineLengthText;
	 	var intSpacePos;
	 	
	 	if (strText.length() < intMaxLineLength) {
	 	  return -1;
	 	} else {
	 	 	strLeftOfLineLengthText =  strText.substring(0, intMaxLineLength);
	 	 	/// now find last space before end
	 	 	intSpacePos = lastIndexOf( " ", strLeftOfLineLengthText);	 	 	
	 	}
	 	return intSpacePos;
	   	 
	 } // end findlastspacebeofer


	 function ChooseFontBasedOnLengthAndSetColorFenix5( strQuote, dc ) { // passed in dc so i can change color!
	var myFont = null; 
	//var dblFontSizeFactor = 1;
	var intQuoteLength = strQuote.length();

	if (intQuoteLength > 250 ) {
		
			myFont = $.customFontSmall;
		Sys.println( "font size is xtiny Length is " + strQuote.length());
		} else if (intQuoteLength > 65 ) {
			gRowHeight = 20;			
			myFont = Gfx.FONT_TINY;
			Sys.println( "font size is tiny Length is " + strQuote.length());
		
		} else if ( intQuoteLength > 50 )  {
			gRowHeight = 21;
		   myFont = Gfx.FONT_SMALL;
		 Sys.println( "font size is small Length is " + strQuote.length());
		
		} else if ( intQuoteLength > 30 ) {
			gRowHeight = 30;//33	
			myFont  = Gfx.FONT_MEDIUM;
		Sys.println( "font size is med  Length is " + strQuote.length());
					
		} else if ( intQuoteLength > 27 ){
		gRowHeight = 30;
		  myFont = Gfx.FONT_LARGE;
		  Sys.println( "font size is large. Length is " + strQuote.length());
		  Sys.println( strQuote );
		  } else {
		  myFont = customFontLarge;
		  gRowHeight = 40;
		   dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_BLACK);
		 Sys.println( "font size is xlarge");
		  
		  
		} // will default to large
		return myFont; 
	} // end ChooseFontBasedOnLengthAndSetColorFenix5


   function GetKMMovedDbl(dblDistanceInCentimeters) {
		
		//eg return  1.456788
		var dblKMMoved = 0.0;
		
		if (dblDistanceInCentimeters != null) {
	    	dblKMMoved = dblDistanceInCentimeters/100000.0;
	
	    	
	    }
	
	    return  dblKMMoved;
		
    } // GetKMMOvedDbl

		 function lastIndexOf(charFind, strSource)
	{
		var index = 0;
		var i = 0;
		//var strOriginalSource = strSource;
		var intLocOfSpace;
		while(i<strSource.length())
		{
			intLocOfSpace = strSource.find(charFind);
			// Update index if match is found
			if(intLocOfSpace!= null)
			{
				
				index = index+ intLocOfSpace+1;   
				//Sys.println("space found at  " + intLocOfSpace + " for '" + strSource +"'");  
				// substring to only search rest
				strSource = strSource.substring(intLocOfSpace+1, strSource.length());       
				//Sys.println("new source '" + strSource + "'"); 
			}
			i++;
			
		}

		//	Sys.println("last space is at " + index + " for " + strOriginalSource);
    	return index-1;
	} //lastIndexOf


} // end class
