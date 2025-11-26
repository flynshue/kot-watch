import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.Math;

class kot_watchView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function getHeartRate() as String {
        var heartRate = Activity.getActivityInfo().currentHeartRate;
        if (heartRate != null) {
            return Lang.format("$1$ bpm", [heartRate]);
        } else {
            return "-- ";
            // return Lang.format("$1$", ["1200"]);
        }
    }

    function getActiveCalories() as String {
        var currentCalories = ActivityMonitor.getInfo().calories;
        var profile = UserProfile.getProfile();
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var age = today.year - profile.birthYear;
        var weight = profile.weight / 1000.0;
        var restCalories;
        if (profile.gender == UserProfile.GENDER_MALE) {
            restCalories = 5.2 - 6.116*age + 7.628*profile.height + 12.2*weight;
        } else {
            restCalories = -197.6 - 6.116*age + 7.628*profile.height + 12.2*weight;
        }
        var minutesSinceMidnight = today.hour * 60 + today.min;
        restCalories = Math.round(minutesSinceMidnight * restCalories / 1440).toNumber();
        var activeCalories = currentCalories - restCalories;
        if (activeCalories < 0) {
            activeCalories = 0;
        }

        System.println("Rest Cal:" + restCalories);
        System.println("Current Cal:" + currentCalories);

        return Lang.format("$1$", [activeCalories]);

    }

    function getDataField(fieldChoice as Number) as String {
        var activityInfo = ActivityMonitor.getInfo();
        if (fieldChoice == 0 ) {
            // Steps
            return Lang.format("$1$", [activityInfo.steps]);
        } else if (fieldChoice == 1) {
            // Heart Rate
            return getHeartRate();
        } else if (fieldChoice == 2) {
            // Active Calories
            return getActiveCalories();
        } else {
            // Weather
            return "Weather TBD";
        }
    }

    function drawDataFieldIcons(dc as Dc, fieldChoice as Number, x as Number, y as Number) as Void {
        var icon = null;
        if (fieldChoice == 0) {
            // Steps icon
            icon = Application.loadResource(Rez.Drawables.StepsIcon);
            dc.drawBitmap(x,y, icon);
        } else if (fieldChoice == 1) {
            // Heart rate icon
            icon = Application.loadResource(Rez.Drawables.HeartRateIcon);
            dc.drawBitmap(x,y, icon);
        } else if (fieldChoice == 2) {
            // Active calories icon
            icon = Application.loadResource(Rez.Drawables.CaloriesIcon);
            dc.drawBitmap(x, y, icon);
        }
    }


    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
            }
        } else {
            if (Application.Properties.getValue("UseMilitaryFormat")) {
                timeFormat = "$1$$2$";
                hours = hours.format("%02d");
            }
        }
        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);

        // Get and display the battery level
        var batteryLevel = System.getSystemStats().battery;
        var batteryIcon;
        if (batteryLevel > 75) {
            batteryIcon = Rez.Drawables.BatteryFull;
        } else if (batteryLevel > 50) {
            batteryIcon = Rez.Drawables.BatteryHigh;
        } else if (batteryLevel > 25) {
            batteryIcon = Rez.Drawables.BatteryMedium;
        } else {
            batteryIcon = Rez.Drawables.BatteryLow;
        }

        // Get and display the date
        var today = Time.today();
        var infoMed = Time.Gregorian.info(today, Time.FORMAT_MEDIUM);
        var info = Time.Gregorian.info(today, Time.FORMAT_SHORT);
        var dateString = Lang.format("$1$ $2$/$3$", [infoMed.day_of_week, info.month, info.day]);

        // Get all data field values (before View.onUpdate)
        var bottomDataFieldChoice = Application.Properties.getValue("BottomDataField");
        var bottomDataText = getDataField(bottomDataFieldChoice);
        var leftDataFieldChoice = Application.Properties.getValue("LeftDataField");
        var leftDataText = getDataField(leftDataFieldChoice);
        var rightDataFieldChoice = Application.Properties.getValue("RightDataField");
        var rightDataText = getDataField(rightDataFieldChoice);

        View.onUpdate(dc);

        var iconOffset = 10;
        var foregroundColor = Application.Properties.getValue("ForegroundColor") as Number;

        // Draw time
        var timeX = dc.getWidth() / 2;
        var timeY = 160;
        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(timeX, timeY, Graphics.FONT_NUMBER_MEDIUM, timeString, Graphics.TEXT_JUSTIFY_CENTER);

        // Draw date (centered)
        var dateX = dc.getWidth() / 2;
        var dateY = 150;
        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dateX, dateY, Graphics.FONT_XTINY, dateString, Graphics.TEXT_JUSTIFY_CENTER);

        // Draw battery icon dynamically positioned after battery text
        var batteryText = Lang.format("$1$%", [batteryLevel.format("%.0f")]);
        var batteryTextDim = dc.getTextDimensions(batteryText, Graphics.FONT_XTINY);
        var batteryIconWidth = 32;
        var batteryTotalWidth = batteryTextDim[0] + 5 + batteryIconWidth;
        var batteryStartX = (dc.getWidth() / 2) - (batteryTotalWidth / 2);
        var batteryTextX = batteryStartX;
        var batteryIconX = batteryStartX + batteryTextDim[0] + 5;
        var batteryIconY = 55;
        var batteryIconBitmap = Application.loadResource(batteryIcon);
        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(batteryTextX, batteryIconY, Graphics.FONT_XTINY, batteryText, Graphics.TEXT_JUSTIFY_LEFT);
        dc.drawBitmap(batteryIconX, batteryIconY, batteryIconBitmap);

        // Bottom data field (center-aligned)
        var bottomTextDim = dc.getTextDimensions(bottomDataText, Graphics.FONT_XTINY);
        var bottomIconWidth = 32;
        var bottomTotalWidth = bottomIconWidth + iconOffset + bottomTextDim[0];
        var bottomStartX = (dc.getWidth() / 2) - (bottomTotalWidth / 2);
        var bottomIconX = bottomStartX;
        var bottomTextX = bottomStartX + bottomIconWidth + iconOffset;
        var bottomY = 360;
        drawDataFieldIcons(dc, bottomDataFieldChoice, bottomIconX, bottomY);
        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(bottomTextX, bottomY, Graphics.FONT_XTINY, bottomDataText, Graphics.TEXT_JUSTIFY_LEFT);

        // Left field
        var leftIconX = 20;
        var leftTextX = leftIconX + 32 + iconOffset;  // 32 = icon width, iconOffset = gap
        var leftY = 200;
        drawDataFieldIcons(dc, leftDataFieldChoice, leftIconX, leftY);
        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(leftTextX, leftY, Graphics.FONT_XTINY, leftDataText, Graphics.TEXT_JUSTIFY_LEFT);

        // // Right field
        var rightTextDim = dc.getTextDimensions(rightDataText, Graphics.FONT_XTINY);
        var rightTextX = 396;
        var rightIconX = rightTextX - rightTextDim[0] - iconOffset - 32;
        var rightY = 200;
        drawDataFieldIcons(dc, rightDataFieldChoice, rightIconX, rightY);
        dc.setColor(foregroundColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(rightTextX, rightY, Graphics.FONT_XTINY, rightDataText, Graphics.TEXT_JUSTIFY_RIGHT);

    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

}
