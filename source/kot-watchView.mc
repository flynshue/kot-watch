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
        }
    }

    function getActiveCalories() as String {
        var totalCalories = ActivityMonitor.getInfo().calories;
        var profile = UserProfile.getProfile();
        var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var age = today.year - profile.birthYear;
        var weight = profile.weight / 1000.0;
        var restCalories;
        if (profile.gender == UserProfile.GENDER_MALE) {
            restCalories = 5.2 - 6.116*age + 7.628*profile.height + 12.2*weight;
        } else {
            restCalories = 197.6 - 6.116*age + 7.628*profile.height + 12.2*weight;
        }
        var minutesSinceMidnight = today.hour * 60 + today.min;
        restCalories = Math.round(minutesSinceMidnight * restCalories / 1440).toNumber();
        var activeCalories = totalCalories - restCalories;
        return Lang.format("$1$", [totalCalories]);
        // return Lang.format("$1$", [activeCalories]);
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

        // Update the view
        var view = View.findDrawableById("TimeLabel") as Text;
        view.setColor(Application.Properties.getValue("ForegroundColor") as Number);
        view.setText(timeString);

        // Get and display the battery level
        var batteryLevel = System.getSystemStats().battery;
        var batteryView = View.findDrawableById("BatteryLabel") as Text;
        batteryView.setColor(Application.Properties.getValue("ForegroundColor") as Number);
        batteryView.setText(Lang.format("$1$%", [batteryLevel.format("%.0f")]));
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
        var batteryIconView = View.findDrawableById("BatteryIcon") as Bitmap;
        batteryIconView.setBitmap(batteryIcon);

        // Get and display the date
        var today = Time.today();
        var info = Time.Gregorian.info(today, Time.FORMAT_MEDIUM);
        var dateString = Lang.format("$1$ $2$ $3$", [info.day_of_week, info.month, info.day]);
        var dateView = View.findDrawableById("DateLabel") as Text;
        dateView.setColor(Application.Properties.getValue("ForegroundColor") as Number);
        dateView.setText(dateString);

        // Get and display the bottom data field based on user setting
        var bottomDataFieldChoice = Application.Properties.getValue("BottomDataField");
        var bottomDataView = View.findDrawableById("BottomDataLabel") as Text;
        bottomDataView.setColor(Application.Properties.getValue("ForegroundColor") as Number);
        var bottomDataText = getDataField(bottomDataFieldChoice);
        bottomDataView.setText(bottomDataText);

        // Get and display the left data field based on user setting
        var leftDataFieldChoice = Application.Properties.getValue("LeftDataField");
        var leftDataView = View.findDrawableById("LeftDataLabel") as Text;
        leftDataView.setColor(Application.Properties.getValue("ForegroundColor") as Number);
        var leftDataText = getDataField(leftDataFieldChoice);
        leftDataView.setText(leftDataText);

        // Get and display the right data field based on user setting
        var rightDataFieldChoice = Application.Properties.getValue("RightDataField");
        var rightDataView = View.findDrawableById("RightDataLabel") as Text;
        rightDataView.setColor(Application.Properties.getValue("ForegroundColor") as Number);
        var rightDataText = getDataField(rightDataFieldChoice);
        rightDataView.setText(rightDataText);
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var iconOffset = 40;

        // Bottom data field (center-aligned)
        var bottomTextDim = dc.getTextDimensions(bottomDataText, Graphics.FONT_XTINY);
        var bottomIconX = (dc.getWidth() / 2) - (bottomTextDim[0] / 2) - iconOffset;
        drawDataFieldIcons(dc, bottomDataFieldChoice, bottomIconX, 360);

        // Left field
        var leftTextDim = dc.getTextDimensions(leftDataText, Graphics.FONT_XTINY);
        var leftIconX = 20;
        drawDataFieldIcons(dc, leftDataFieldChoice, leftIconX, 200);

        // Right field
        var rightTextDim = dc.getTextDimensions(rightDataText, Graphics.FONT_XTINY);
        var rightIconX = 396 - rightTextDim[0] - 40;
        drawDataFieldIcons(dc, rightDataFieldChoice, rightIconX, 200);
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
