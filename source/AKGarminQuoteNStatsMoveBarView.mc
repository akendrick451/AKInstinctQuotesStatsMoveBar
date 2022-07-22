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

var gRowHeight = 35; 
var customFontSmall = null; // esp for fenix style watches.
var gNumAPIMajorVersion = 0; // will be major version, usual 1, 2, or 3. 1 cannot have battery stats. 
var gStrCurrentQuote ="Run the race to the finish!";
var gStrDeviceName = ""; //default to blank - set to 235 later
var gIntExtraXRequired=0;
var gIntHeartRate=0;
var gStrHRBackColour=Gfx.COLOR_BLACK;
var gStrHRFontColour=Gfx.COLOR_WHITE;
var gStrBBBackColour=Gfx.COLOR_BLACK;
var gStrBBFontColour=Gfx.COLOR_WHITE;		

// to run this file in vs code
// you can just go to run \ debug
// to build for a different device, select View Command Pallette and then build for device

class AKGarminQuotesStatsMoveBarView extends Toybox.WatchUi.WatchFace {
	
	// how to build in vs code
    var strVersion = "v2.9c";// again checking out git; 
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

    var gNumberOfLinesToPrint=5;
    var gXForTextLoc = 30;
    var gIntFontSize=10;
    var gIntLastMoveBarLevel=0;
    var gIntNumberOfMovedHours= 0;
    
    var gStrPartNumberDevice = "";
    
    var gTinyFont = null;
	

 public function initialize() {
        WatchFace.initialize();
		//Session.start();
		}

    // Load your resources here
    function onLayout(dc) {
     customFontSmall = Ui.loadResource(Rez.Fonts.akSmallFont);
     customFontLarge = Ui.loadResource(Rez.Fonts.customFontLarge);
     gTinyFont = customFontSmall;
     var mySettings = System.getDeviceSettings();
		gStrPartNumberDevice = mySettings.partNumber;
		Sys.println("Part number is '" + gStrPartNumberDevice + "'");
		// fenix 5 =006-B3110-00, fs = 006-B2544-00
		// forerunner 235 = 006-B2431-00
		if (gStrPartNumberDevice.equals("006-B2431-00")) {
			gTinyFont = Gfx.FONT_XTINY;
			Sys.println("Assuming forerunner 235...Setting font to by system");
			gStrDeviceName="Forerunner235";
			gIntExtraXRequired = 10;
		}
		

		// check which api/sdk version this device supports
			var version = mySettings.monkeyVersion;
			var versionString = Lang.format("$1$.$2$.$3$", version);
			System.println(versionString); //e.g. 2.2.5
		    gNumAPIMajorVersion = version[0];
     		System.println(gNumAPIMajorVersion); //e.g. 2 or 1
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    
    // Update the view
    function onUpdate(dc) {

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
		var minute = clockTime.min;
		var second = clockTime.sec;
        // Get and show the current time
        
        if (!Sys.getDeviceSettings().is24Hour) {
        	hour = hour % 12;
        	if (hour==0) {
        		hour = 12;
        	}
        } // end if
	
		// =====================================================================            
		// Draw the clock / time     , version and heart rate and body battery
		// =====================================================================
	    dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_BLACK);
	    dc.drawText(dc.getWidth()/2, 1, Gfx.FONT_LARGE, hour.toString()+ " ", Gfx.TEXT_JUSTIFY_RIGHT);
	    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
	    dc.drawText(dc.getWidth()/2, 1, Gfx.FONT_MEDIUM, Lang.format("$1$", [clockTime.min.format("%02d")]), Gfx.TEXT_JUSTIFY_LEFT);	    
	    
	     // and the version	     
	     //dc.drawText(dc.getWidth()-50, 1, Gfx.FONT_SYSTEM_XTINY, strVersion, Gfx.TEXT_JUSTIFY_RIGHT);
	     // draw multiple versions to see what size we want
	     //dc.drawText(dc.getWidth()-50, 50, Gfx.FONT_SYSTEM_NUMBER_MILD, strVersion, Gfx.TEXT_JUSTIFY_RIGHT);
	    dc.drawText(dc.getWidth()-50, 20, $.customFontSmall, strVersion, Gfx.TEXT_JUSTIFY_RIGHT);
		
		//  ==================================================
		//  draw  heart rate
		//  ==================================================
		// just beneath version, print heart rate
		
		// get a HeartRateIterator object; oldest sample first
		var intHeartRate = 0; 
		intHeartRate = getHeartRateAndSetColours(); //set gStrHRBackColor and gStrHRFontColor;
		if (intHeartRate != 0){
		
			dc.setColor(gStrHRFontColour,gStrHRBackColour);
			dc.drawText(dc.getWidth()-40, 32, 1, "HR:" + intHeartRate, Gfx.TEXT_JUSTIFY_RIGHT);
			dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);
		} //  print  heart  rate if not zerro

	// get body battery if available
	
		var dblBodyBatteryNumber = 0.0;
		dblBodyBatteryNumber = getBodyBatteryPercentAndSetColours();
		
		if (dblBodyBatteryNumber!=0.0) {
			dc.setColor(gStrBBFontColour, gStrBBBackColour);
			dc.drawText(47,20 , 1, "BB" + dblBodyBatteryNumber.format("%.0f"), Gfx.TEXT_JUSTIFY_LEFT);
			dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
		}	else {
			dc.drawText(47, 20, 1, "Bnull" , Gfx.TEXT_JUSTIFY_LEFT);
		}
		// ====================end draw bb ===============================


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
		if (  (minute > 10 && minute < 20)|| ( minute > 40 && minute < 50) ) {
			// show weeks movement history
			DrawWeeksMovementHistory(dc);
			System.println("do weeks movement");
		
		} else {
			// only want to redraw quote every hour or so???? Dn't want to change every second
			var hourMod2 = hour % 2;
			// only change quote every odd hour and if the minute is 0 
			// so change quote every 2 hours!
			if (  ((minute == 31) || (minute == 0)) && (second <= 10)) {
				SetNewQuote();
			//	GetQuoteSizeAndDraw(dc);
			}
			DrawQuote(dc);
		
				
		} // end if hour - 7	    
	    dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_BLACK); // just in case we changed it 
	
		// =====================================================================	    
	    // Put some battery stats	    
		// =====================================================================	    
		var myStats = System.getSystemStats();
		//System.println(myStats.battery);
		//System.println(myStats.totalMemory);
		var strBatteryPercent = Lang.format("$1$",[myStats.battery.format("%02d")])+ "%";	    
		
		var batteryX = 59;
		var batteryHeight = 28; // was 14
		
		var batteryWidth = 38;
		var dateAndBatteryHeight = 46;
		// put battery lower for 235
		if (gStrDeviceName.equals("Forerunner235")) {
			batteryHeight = 20;
			dateAndBatteryHeight = 26;
			batteryWidth = 30;
		}
		var dateStartYBatteryAndDate = dc.getHeight()-dateAndBatteryHeight-5;
		var batteryY = dateStartYBatteryAndDate+8; //+4
		var intNippleMid = batteryHeight/2;
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
		 	lineColor = Gfx.COLOR_RED;
		 	backColor = Gfx.COLOR_RED;
		 	dc.drawRoundedRectangle(batteryX-4, batteryY, batteryWidth, batteryHeight,1 );
		 } else if ( myStats.battery < intBatteryWarning  ) {		
		 	textColor = Gfx.COLOR_WHITE;
		 	lineColor = Gfx.COLOR_WHITE; //should be yello
		 	backColor = Gfx.COLOR_YELLOW;
		 } else {
			textColor = Gfx.COLOR_WHITE;
		 	lineColor = Gfx.COLOR_WHITE;
		 	backColor = Gfx.COLOR_DK_GREEN;
		 }

		//if battery is charging, set an orange dot or something - a z
		// battery charging stas only availabe after?  version 3
		System.println(gNumAPIMajorVersion); //e.g. 2 or 1)
		if (gNumAPIMajorVersion>= 3) {
			if (myStats.charging!=0) {
			dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_BLACK);
			dc.drawText(batteryX-18, batteryY-2 ,  Gfx.FONT_TINY, "z" , Gfx.TEXT_JUSTIFY_LEFT);
			} // end if chargin
		} // if version > 3
		 
         dc.setColor(textColor,backColor);		 	
	     dc.drawText(batteryX, batteryY ,  Gfx.FONT_TINY,strBatteryPercent , Gfx.TEXT_JUSTIFY_LEFT);
	     //draw a box around the battery that looks like a battery?	     
	     
	     dc.setColor(lineColor,textColor); 	
	     dc.drawRoundedRectangle(batteryX-2, batteryY, batteryWidth, batteryHeight,1 );	       	
	     // draw the battery nipple - just the nipple     
		 //dc.drawRoundedRectangle(x, y, width, height, radius)
	   //  dc.drawRoundedRectangle(batteryX-5, batteryY+9, 4, 12, 2);
		   dc.drawRoundedRectangle(batteryX-5, intNippleY, 4, intNippleHeight, 2);
		 
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
		var gTinyFont = Gfx.FONT_TINY; // will make the date bigger than battery stats
		//	dateStartYBatteryAndDate = 200;
		try {
			// Code to execute
		//	if(gStrDeviceName.equals("Forerunner235")) {
		//		dateStartYBatteryAndDate = dateStartYBatteryAndDate + 4;
		//	}
			dc.drawText(dc.getWidth()-48, dateStartYBatteryAndDate+8, gTinyFont, dateStr , Gfx.TEXT_JUSTIFY_RIGHT);
		} catch( ex ) {
		// Code to catch all execeptions
			System.println("exception is 76 : " + ex.getErrorMessage());
		}
		
	    // =====================================================================
	    // show kms travelled
	    // =====================================================================
	    DrawKMTravelledAndMoveBar(dc);
	    	  //  drawTextOverMultiLines( dc, "Let us run the race that is set before us.");	    	    	    
	} // end onUpdate

	

	function getBodyBatteryPercentAndSetColours() {
		
		var dblBodyBatteryPercent = 0.0;
		var objABodyBattery=null;
		var bbIterator = getBodyBatteryIterator();
		if (bbIterator!=null)  {
		 objABodyBattery = bbIterator.next();                         // get the body battery data
		}
		if (objABodyBattery != null) {
			System.println("Sample: " + objABodyBattery.data);           // print the current sample
			dblBodyBatteryPercent = objABodyBattery.data;
		}

		//========set colors based on time of day AND Percent ================
		if (dblBodyBatteryPercent == null) {
			dblBodyBatteryPercent = 0.0;
		}
		var intCurrentHourOfDay = getHourOfDay();
		var intCurrentMinutes = getMinutesOfHour() ;// eg if time is 7:45, return 45 // 1-60

// test - set dblBodyBatteryNumber to various numbers
	dblBodyBatteryPercent =30;

		if(dblBodyBatteryPercent!=0.0){

			// try to get some equation to check if percentage of body battery is > percentage of day left
			// assume day starts at 8am and finishes at 10pm or 22:00. 
			var intStartOfDayHour = 8;
			var intFinishOfDayHour = 22;
			var intHoursInDay = intFinishOfDayHour - intStartOfDayHour;
			var intHoursLeftInDay = intFinishOfDayHour-intCurrentHourOfDay;
			
			// better to compare minutes than hours 
			var intMinutesLeftInDay = intHoursLeftInDay*60 -(60- intCurrentMinutes);
			var intTotalMinutesAwake = intHoursInDay * 60;
			var dblPercentOfDayLeftByMinutes =  100*(intMinutesLeftInDay.toDouble()/intTotalMinutesAwake.toDouble());

			var dblPercentOfDayLeft =  100*(intHoursLeftInDay.toDouble()/intHoursInDay.toDouble());
			var intBBTolerance = 10;
			var intDiffDayLeftAndBB = (dblBodyBatteryPercent)-dblPercentOfDayLeftByMinutes;

			// lets add a pink if in tolerance
			

			if( intDiffDayLeftAndBB > 0) { // ie body battery % > day left % . Very good
				 gStrBBBackColour=Gfx.COLOR_BLACK;
				 gStrBBFontColour=Gfx.COLOR_WHITE;	
			} else if ((intDiffDayLeftAndBB + intBBTolerance) > 0) {
				// eg day left=40 and we are 35. 
				 gStrBBBackColour=Gfx.COLOR_BLACK;
				 gStrBBFontColour=Gfx.COLOR_PINK; // pink is easier to read than orange. 
			} else if (intDiffDayLeftAndBB > -20)  {
				// eg say we are 10-20 below day left, eg day left - 40 we are 25 
				 gStrBBBackColour=Gfx.COLOR_BLACK;
				 gStrBBFontColour=Gfx.COLOR_RED;	
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
		var dateString = Lang.format(
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
		);
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
				var previous = hrIterator.next();                                   // get the previous HR
				var lastSampleTime = null;        
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
			gStrHRBackColour = Gfx.COLOR_RED;
			gStrHRFontColour = Gfx.COLOR_BLACK;
		} else if (intHeartRate >= 100) {
			gStrHRBackColour = Gfx.COLOR_BLACK;
			gStrHRFontColour = Gfx.COLOR_RED;
		} else if (intHeartRate >= 80) {
			gStrHRBackColour = Gfx.COLOR_BLACK;
			gStrHRFontColour = Gfx.COLOR_PINK;
		} else if (intHeartRate > 30 && intHeartRate <60) {
			gStrHRBackColour = Gfx.COLOR_BLACK;
			gStrHRFontColour = Gfx.COLOR_GREEN;
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

			
			var intNumberOfDaysHistoryToShow = 5;
	
		var dailyHistoryArr = ActivityMonitor.getHistory(); //gets 7 days history
			/* System.println("Draw previous history") print the previous sample
			   System.println("history array size is " + dailyHistoryArr.size() );  // print the previous sample
			  */  
			// GEt the current day eg Monday/Tuesday/Wednessay to work out what days we have			
			var infoDateTimeNow = Gregorian.info(Time.now(), Time.FORMAT_SHORT); // 6= friday
			 System.println(infoDateTimeNow.day_of_week);
			 var intDayOfWeekToday = infoDateTimeNow.day_of_week; 
			 // eg 6 = friday

			System.println("Today is " + 			GetShortDayNameFromNumber(intDayOfWeekToday));						
			var intYForStats = dc.getHeight()-100;

			var intXLocationForDay = 30 + gIntExtraXRequired;
			var intXLocationForKms = 80 + gIntExtraXRequired; 
			// dc.getWidth()/2;
			var strDayOfReading = "";
			var dblDistanceInKmsForDay = 0.0;			    
			var strComment = "";
			var strText = "";
			var dblTotalKmsForWeek = 0.0;
			var intHeightOfText = 20;
			if (gStrDeviceName.equals("Forerunner235")){
				intHeightOfText=14;
				intYForStats = dc.getHeight() - 70;
			}
			
			var fontSize = 1; //smallest font size;
			try {
			// loop through the 7 day history on the watch			    
			for( var i = 0; i < dailyHistoryArr.size(); i++ ) { 
				if( i < intNumberOfDaysHistoryToShow ) { // i only want to show 4 days history plus today				
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
				

				dc.drawText(intXLocationForDay, intYForStats-(intHeightOfText*(5)), fontSize, "Week ", Gfx.TEXT_JUSTIFY_LEFT);
				dc.drawText(intXLocationForKms+ 20, intYForStats-(intHeightOfText*(5)), fontSize,
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
		var xForStepsAndKms = 40 + gIntExtraXRequired;
	    var yForStepsKMAndMoveNumber = dc.getHeight()-73; // was 69
		if (gStrDeviceName.equals("Forerunner235")) {
			yForStepsKMAndMoveNumber = dc.getHeight()-43; 
		}
	    var strKMMoved = 0;
		//var dblKMMoved = GetTodaysDistanceKMDbl();
	    strKMMoved = GetTodaysDistanceKMStr();
		var	    strSteps = 0;
	    if ( ActivityMonitor.getInfo().steps != null) {
	   	 strSteps =  ActivityMonitor.getInfo().steps;
	    }
	    
	   // does not work on forerunner 235! it's not a cq2 device! var strActiveMinutes = ActivityMonitor.getInfo().activeMinutesDay; 
	    
	    var strStepsAndKms = convertToThousandsShorthand(strSteps) + "k stps/" + strKMMoved + " kms";
	    dc.drawText(xForStepsAndKms, yForStepsKMAndMoveNumber, Gfx.FONT_SMALL, strStepsAndKms , Gfx.TEXT_JUSTIFY_LEFT);
	    
   	    // =====================================================================
	    // add move bar - red
	    // =====================================================================
	    if (ActivityMonitor.getInfo().moveBarLevel > 0) {
		    dc.setColor(Gfx.COLOR_RED,Gfx.COLOR_BLACK); // just in case we changed it 	     
		    var startXForMoveBarValue = dc.getWidth()-20;
		    dc.drawText(startXForMoveBarValue, yForStepsKMAndMoveNumber-10, Gfx.FONT_SMALL,ActivityMonitor.getInfo().moveBarLevel , Gfx.TEXT_JUSTIFY_RIGHT);	    	    
	   }
	    var intMoveBarLevelCurrent = ActivityMonitor.getInfo().moveBarLevel;	    	     
	     if (gIntLastMoveBarLevel > 0) {
		     if (ActivityMonitor.getInfo().moveBarLevel==0) {
    	     	gIntNumberOfMovedHours=gIntNumberOfMovedHours+1 ; // might need to reset this each day
		     }
		   }
	      gIntLastMoveBarLevel=intMoveBarLevelCurrent;
	      Sys.println("-------------------- Move bar level ------------------------------");
	      Sys.println("Last level = " + gIntLastMoveBarLevel + ", current level = " + intMoveBarLevelCurrent);
	      Sys.println("Number of hours moved = " + gIntNumberOfMovedHours);
	      Sys.println("-------------------- Move bar level ------------------------------");
	    var moveBarLength = ActivityMonitor.getInfo().moveBarLevel*25;	    	    
	   // dc.drawLine(40, startY, 40+moveBarLength, startY);
	    dc.drawRectangle(xForStepsAndKms, yForStepsKMAndMoveNumber-2, moveBarLength, 2);
	    // dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_BLACK); // just in case we changed it 
	     // and draw a thiker? bar to highliht 
	     dc.drawRectangle(xForStepsAndKms, yForStepsKMAndMoveNumber, moveBarLength, 2);
	    
	
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
		
		var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		var r;	
		r = Mt.rand() % arrQuotes.size(); //Random number			
		//r = today.day_of_week-1; // get based on day of week,n ot random
		//Sys.println(r); //To check the result
		//r=0;
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
		
		var intLenLeftToPrint = strText.length();
		var yStartPosition = 30; // starting y position
	
	 	//Sys.println("length is  " + strText.length() + " number which can fit on line =" + intCharsPerLine);
		var intNumberOfLinesNeeded = (strText.length()*1.00)/(intCharsPerLine-2)*1.00; //-2 is a fudge because God loves me is going on 3 lines but this returns 2~!!!!!
		//Sys.println("number of lines needed = " + intNumberOfLinesNeeded);
		
		
		Sys.println("intNumberOfLinesNeeded= "  + intNumberOfLinesNeeded + " yStartPosition is " + yStartPosition + " rowHeight is " + rowHeight);
		if (intNumberOfLinesNeeded == 1 ) {
		       yStartPosition = dc.getHeight()/2-rowHeight; //- put it in the middleish!
		   //Sys.println("1 lines exactly... put it in the middle!");
		
		}
		
				if (intNumberOfLinesNeeded > 1 && intNumberOfLinesNeeded<2 ) {
		       yStartPosition = dc.getHeight()/2-rowHeight*1.2; //- put it in the middleish!
		     //Sys.println("2 lines needed ... put it in the 2iddle!");
		
		}
		
		
		if (intNumberOfLinesNeeded > 2 && intNumberOfLinesNeeded < 3) {
		       yStartPosition = dc.getHeight()/2-rowHeight*1.5; //- put it in the middleish!
		    //Sys.println("three lines... put it in the middle!");
		
		}
		
		if (intNumberOfLinesNeeded >= 3 && intNumberOfLinesNeeded < 4) {
		       yStartPosition = dc.getHeight()/2-rowHeight*2.1; //- put it in the middleish!
		      //Sys.println("4 lines... put it in the middle!");
		
		}
		
		if (intCharsPerLine > strText.length() ) {
				// if we all fit on one line... 
		 yStartPosition = dc.getHeight()/2-rowHeight*0.8; //- put it in the middle!
		     //Sys.println("Only 1 line.. try to put it in themiddle");
		}
		
		Sys.println("yStartPosition is " + yStartPosition + " rowHeight is " + rowHeight);
		var intLastSpaceLoc;
		
		
		var intLocOfLastSpace=0;
		
		// print out the words on multiple lines
		//Sys.println("Starting to get each line...");
		do {
		   
		   // find last " " before the width allowed.
		   
		   intLastSpaceLoc = findLastSpaceBeforeLineLength( strText, intCharsPerLine );
//Sys.println("Last Space loc = " + intLastSpaceLoc);		   
		   if (intLastSpaceLoc == -1) {
		    	intLastSpaceLoc = intLenLeftToPrint;
		   }		   		   
		   var strPrintThis = strText.substring(0, intLastSpaceLoc); // need to fix this to find first " " before end
		   //intLocOfLastSpace = strPrintThis.find( 
		   strText = strText.substring(intLastSpaceLoc+1, strText.length());
		   intLenLeftToPrint = strText.length();
		   dc.drawText(gXForTextLoc,yStartPosition, myFont, strPrintThis, Gfx.TEXT_JUSTIFY_LEFT);
		   yStartPosition = yStartPosition + gRowHeight; 
		} while  (intLenLeftToPrint > intCharsPerLine );
		
		// draw anything left 
		dc.drawText(gXForTextLoc,yStartPosition, myFont, strText, Gfx.TEXT_JUSTIFY_LEFT);
		
	} //drawTextOverMultiLines


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
	if (strQuote.length() > 250 ) {
		
			myFont = Gfx.FONT_XTINY;
		Sys.println( "font size is xtiny Length is " + strQuote.length());
		} else if (strQuote.length() > 160 ) {
			gRowHeight = 5;			
			myFont = Gfx.FONT_TINY;
			Sys.println( "font size is tiny Length is " + strQuote.length());
		
		} else if ( strQuote.length() > 90 )  {
			gRowHeight = 23;
		   myFont = Gfx.FONT_SMALL;
		 Sys.println( "font size is small Length is " + strQuote.length());
		
		} else if ( strQuote.length() > 50 ) {
			gRowHeight = 22;	
			myFont  = Gfx.FONT_MEDIUM;
		Sys.println( "font size is med  Length is " + strQuote.length());
					
		} else if ( strQuote.length() > 31 ){
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
		var strOriginalSource = strSource;
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
