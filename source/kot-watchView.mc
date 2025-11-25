import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.ActivityMonitor;

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
        var dataFieldChoice = Application.Properties.getValue("BottomDataField");
        var activityInfo = ActivityMonitor.getInfo();
        var dataString = "";
        if (dataFieldChoice == 0) {
            // Steps
            dataString = Lang.format("$1$ Steps", [activityInfo.steps]);
        } else if (dataFieldChoice == 1) {
            // Heart Rate
            var heartRate = Activity.getActivityInfo().currentHeartRate;
            if (heartRate != null) {
                dataString = Lang.format("$1$ bpm", [heartRate]);
            } else {
                dataString = "-- bpm";
            }
        } else if (dataFieldChoice == 2) {
            // Calories
            // dataString = Lang.format("$1$ cal", [activityInfo.activeMinutesDay.total != null ? activityInfo.activeMinutesDay.total : 0]);
            dataString = Lang.format("$1$ cal", [activityInfo.activeMinutesDay.total]);
        } else if (dataFieldChoice == 3) {
            // Totla calories
            dataString = Lang.format("$1$ cal", [activityInfo.calories]);
        } else if (dataFieldChoice == 4) {
            // Weather
            dataString = "Weather TBD";

        }

        var dataView = View.findDrawableById("BottomDataLabel") as Text;
        dataView.setColor(Application.Properties.getValue("ForegroundColor") as Number);
        dataView.setText(dataString);

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
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
