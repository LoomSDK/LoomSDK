package co.theengine.loomdemo;


import android.app.Activity;
import android.content.Context;
import android.content.res.Configuration;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.view.Display;
import android.view.Surface;
import android.view.WindowManager;
import android.util.Log;



/**
 * 
 * This class is used for accessing the various Android Sensors
 *
 * NOTE: TYPE_ACCELEROMETER in here is not exposed to the Accelerometer class 
 * as that is all implemented in Cocos2dxAcclerometer.  This could be updated 
 * to use ours instead at some point.  We need our own listener in order to 
 * use .getOrientation().
 *
 */
public class LoomSensors
{
    ///private vars
    private static final String                 TAG = "Loom Sensors";

    private static Context                      _context;
    private static SensorManager                _sensorManager;
    private static int                          _naturalOrientation;
    private static boolean                      _accelerometerEnabled = false;
    private static boolean                      _magnometerEnabled = false;
    private static boolean                      _gyroscopeEnabled = false;
    private static boolean                      _resumeAccelerometer = false;
    private static boolean                      _resumeMagnometer = false;
    private static boolean                      _resumeGyroscope = false;
    private static Sensor                       _accelerometer;
    private static Sensor                       _magnometer;
    private static Sensor                       _gyroscope;
    private static AccelerometerSensorListener  _accelerometerListener;
    private static MagnometerSensorListener     _magnometerListener;
    private static GyroscopeSensorListener      _gyroscopeListener;
    private static boolean                      _accelerometerSupported;
    private static boolean                      _magnometerSupported;
    private static boolean                      _gyroscopeSupported;



    ///class to implement the listerer interface to act upon accelerometer states
    public static class AccelerometerSensorListener implements SensorEventListener
    {
        ///override for SensorEventListener.onSensorChanged
        @Override
        public void onSensorChanged(SensorEvent event)
        { 
            if (event.sensor.getType() != Sensor.TYPE_ACCELEROMETER)
            {
                return;
            }
            
            // If the sensor data is unreliable return
            if(event.accuracy == SensorManager.SENSOR_STATUS_UNRELIABLE)
            {
                return;
            }

            ///get correctly oriented values to work with
            float[] values = remapXYZValues(event.values);
            float x = values[0];
            float y = values[1];
            float z = values[2];
            // Log.d(TAG, "Accelerometer Sensor Changed: x = " + x + " y = " + y + " z = " + z);
///TODO: FLAG ARRAY FOR ORIENTATION UPDATE            
 
// onAccelerometerChanged(x, y, z, event.timestamp);
        }


        ///dummy stub override for SensorEventListener.onAccuracyChanged
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) 
        {
        }   
    }



    ///class to implement the listerer interface to act upon magnometer states
    public static class MagnometerSensorListener implements SensorEventListener
    {
        ///override for SensorEventListener.onSensorChanged
        @Override
        public void onSensorChanged(SensorEvent event)
        { 
            if (event.sensor.getType() != Sensor.TYPE_MAGNETIC_FIELD)
            {
                return;
            }
            
            // If the sensor data is unreliable return
            // if(event.accuracy == SensorManager.SENSOR_STATUS_UNRELIABLE)
            // {
            //     return;
            // }

            ///get correctly oriented values to work with
            float[] values = remapXYZValues(event.values);
            float x = values[0];
            float y = values[1];
            float z = values[2];
            // Log.d(TAG, "Magnometer Sensor Changed: x = " + x + " y = " + y + " z = " + z);

///TODO: FLAG ARRAY FOR ORIENTATION UPDATE            
 
// onMagnometerChanged(x, y, z, event.timestamp);
        }  
 

        ///dummy stub override for SensorEventListener.onAccuracyChanged
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) 
        {
        }   
    }



    ///class to implement the listerer interface to act upon gyroscope states
    public static class GyroscopeSensorListener implements SensorEventListener
    {
        ///override for SensorEventListener.onSensorChanged
        @Override
        public void onSensorChanged(SensorEvent event)
        { 
            if (event.sensor.getType() != Sensor.TYPE_GYROSCOPE)
            {
                return;
            }
            
            // If the sensor data is unreliable return
            if(event.accuracy == SensorManager.SENSOR_STATUS_UNRELIABLE)
            {
                return;
            }

            ///get correctly oriented values to work with
            float[] values = remapXYZValues(event.values);
            float x = values[0];
            float y = values[1];
            float z = values[2];
            // Log.d(TAG, "Gyroscope Sensor Changed: x = " + x + " y = " + y + " z = " + z);
 
// onGyroscopeChanged(x, y, z, event.timestamp);
        }


        ///dummy stub override for SensorEventListener.onAccuracyChanged
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) 
        {
        }   
    }




    ///handles initialization of the Loom Sensors class
    public static void onCreate(Activity context)
    {
        _context = context;

        //store sensor manager
        _sensorManager = (SensorManager)_context.getSystemService(Context.SENSOR_SERVICE);

        ///create sensors & listeners
        _accelerometer = _sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        _magnometer = _sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
        _gyroscope = _sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
        _accelerometerListener = (_accelerometer != null) ? new AccelerometerSensorListener() : null;
        _magnometerListener = (_magnometer != null) ? new MagnometerSensorListener() : null;
        _gyroscopeListener = (_gyroscope != null) ? new GyroscopeSensorListener() : null;
        
        ///store base orientation for internal calculations on our sensor values
        Display display = ((WindowManager)_context.getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay();
        _naturalOrientation = display.getOrientation();

///TEMP TEST CODE
enableAccelerometer();        
enableMagnometer();        
enableGyroscope();        
    }


    ///handles destruction of the sensors
    public static void onDestroy()
    {
        disableAccelerometer();
        disableMagnometer();
        disableGyroscope();
    }


    ///handles disabling sensors while the app is paused
    public static void onPause()
    {
        ///disable sensors when paused
        if(_accelerometerEnabled)
        {
            _resumeAccelerometer = true;
            disableAccelerometer();
        }
        if(_magnometerEnabled)
        {
            _resumeMagnometer = true;
            disableMagnometer();
        }
        if(_gyroscopeEnabled)
        {
            _resumeGyroscope = true;
            disableGyroscope();
        }
    }


    ///handles enabling sensors while the app is resumed
    public static void onResume()
    {
        ///enabled sensors when resumed... only if user actually enabled though!
        if(_resumeAccelerometer)
        {
            enableAccelerometer();
            _resumeAccelerometer = false;
        }
        if(_resumeMagnometer)
        {
            enableMagnometer();
            _resumeMagnometer = false;
        }
        if(_resumeGyroscope)
        {
            enableGyroscope();
            _resumeGyroscope = false;
        }
    }


    ///handles enabling the accelerometer
    public static void enableAccelerometer()
    {
        if(!_accelerometerEnabled)
        {
            _accelerometerSupported = false;
            if(_accelerometer != null)
            {
                _accelerometerSupported = _sensorManager.registerListener(_accelerometerListener, _accelerometer, SensorManager.SENSOR_DELAY_GAME);
                _accelerometerEnabled = _accelerometerSupported;
            }
            Log.d(TAG, "Accelerometer Supported: " + _accelerometerSupported);
        }
    }

    ///handles disabling the accelerometer
    public static void disableAccelerometer()
    {
        if(_accelerometerEnabled)
        {
            _sensorManager.unregisterListener(_accelerometerListener);
            _accelerometerEnabled = false;
        }
    }

    ///handles enabling the magnometer
    public static void enableMagnometer()
    {
        if(!_magnometerEnabled)
        {
            _magnometerSupported = false;
            if(_magnometer != null)
            {
                _magnometerSupported = _sensorManager.registerListener(_magnometerListener, _magnometer, SensorManager.SENSOR_DELAY_GAME);
                _magnometerEnabled = _magnometerSupported;
            }
            Log.d(TAG, "Magnometer Supported: " + _magnometerSupported);
        }
    }

    ///handles disabling the magnometer
    public static void disableMagnometer()
    {
        if(_magnometerEnabled)
        {
            _sensorManager.unregisterListener(_magnometerListener);
            _magnometerEnabled = false;
        }
    }

    ///handles enabling the gyroscope
    public static void enableGyroscope()
    {
        if(!_gyroscopeEnabled)
        {
            _gyroscopeSupported = false;
            if(_gyroscope != null)
            {
                _gyroscopeSupported = _sensorManager.registerListener(_gyroscopeListener, _gyroscope, SensorManager.SENSOR_DELAY_GAME);
                _gyroscopeEnabled = _gyroscopeSupported;
            }
            Log.d(TAG, "Gyroscope Supported: " + _gyroscopeSupported);
        }
    }

    ///handles disabling the gyroscope
    public static void disableGyroscope()
    {
        if(_gyroscopeEnabled)
        {
            _sensorManager.unregisterListener(_gyroscopeListener);
            _gyroscopeEnabled = false;
        }
    }



    ///helper to remap the coordinate system for device orientation... concept taken from the Cocos2dx Accelerometer code
    private static float[] remapXYZValues(float[] xyz)
    {
        ///make copy of the array of incoming values
        float[] newValues = xyz.clone();

        /*
         * Because the axes are not swapped when the device's screen orientation changes. 
         * So we should swap it here.
         * In tablets such as Motorola Xoom, the default orientation is landscape, so should
         * consider this.
         */
        int orientation = _context.getResources().getConfiguration().orientation;
        if(_naturalOrientation != Surface.ROTATION_0)
        {
            if(orientation == Configuration.ORIENTATION_LANDSCAPE)
            {
                float tmp = newValues[0];
                newValues[0] = -newValues[1];
                newValues[1] = tmp;
            }
            else if(orientation == Configuration.ORIENTATION_PORTRAIT)
            {
                 float tmp = newValues[0];
                 newValues[0] = newValues[1];
                 newValues[1] = -tmp;
            }
        }

        return newValues;
    }

/*

// Gets the value of the sensor that has been changed
    switch (sensorEvent.sensor.getType()) {  
        case Sensor.TYPE_ACCELEROMETER:
            gravity = sensorEvent.values.clone();
            break;
        case Sensor.TYPE_MAGNETIC_FIELD:
            geomag = sensorEvent.values.clone();
            break;
    }


float[] r = new float[9];
float[] accValues = new float[3];
float[] geoVallues = new float[3];
float[] v = new float[3];
boolean success = SensorManager.getRotationMatrix(
r,
null,
accValues,
geoVallues);

if(success)
{
    SensorManager.getOrientation(r, v);
v[0]: azimuth, rotation around the Z axis.
v[1]: pitch, rotation around the X axis.
v[2]: roll, rotation around the Y axis.
}

//-Using the camera (Y axis along the camera's axis) for an augmented reality application where the rotation angles are needed:
//  remapCoordinateSystem(inR, AXIS_X, AXIS_Z, outR);
//-Using the device as a mechanical compass when rotation is Surface.ROTATION_90:
//  remapCoordinateSystem(inR, AXIS_Y, AXIS_MINUS_X, outR);
*/

    ///native function stubs
    private static native void onAccelerometerChanged(float x, float y, float z, long timeStamp);
    private static native void onMagnometerChanged(float x, float y, float z, long timeStamp);
    private static native void onGyroscopeChanged(float x, float y, float z, long timeStamp);
}
