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
import android.graphics.Matrix;
import android.util.Log;

import org.cocos2dx.lib.Cocos2dxGLSurfaceView;




/**
 * 
 * This class is used for accessing the various Android Sensors
 *
 * NOTE: TYPE_ACCELEROMETER is already implemented in Cocos2dxAcclerometer, so
 * if it is ever added here, it should be removed from there to avoid 2x hardware processing!
 *
 */
public class LoomSensors
{
    ///sensor wrapper class
    public static class AndroidSensor implements SensorEventListener
    {
        ///constants
        private static final float  NS2S    = 1.0f / 1000000000.0f;

        ///private vars
        private Sensor          _sensor;
        private String          _type;
        private boolean         _shouldResume;
        private boolean         _isEnabled;
        private boolean         _isSupported;
        private long            _lastChangedTimestamp;


        ///constructor
        public AndroidSensor(int type)
        {
            ///init data
            _shouldResume = false;
            _isEnabled = false;
            _isSupported = false;
            _lastChangedTimestamp = 0;

            ///create desired sensor
            _sensor = null;
            switch(type)
            {
                case SENSOR_ACCELEROMETER:
                    ///NOTE: Don't use Accelerometer for now...
                    // _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
                    _type = "Accelerometer";
                    break;
                case SENSOR_MAGNOMETER:
                    ///NOTE: Don't use Magnometer for now...
                    // _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
                    _type = "Magnometer";
                    break;
                case SENSOR_GYROSCOPE:
                    ///NOTE: Don't use Gyroscope for now...
                    // _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
                    _type = "Gyroscope";
                    break;
                case SENSOR_ROTATION_VECTOR:
                    ///NOTE: Only supported in Api 9+ (Gingerbread 2.3)
                    _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR);
                    _type = "Rotation Vector";
                    break;
            }

            ///if a valid sensor object was returned, we start off by supporting it
            _isSupported = (_sensor != null) ? true : false;
            Log.d(TAG, "Sensor Type: " + _type + " supported? " + _isSupported);
        }
       

        ///returns supported status
        public boolean isSupported()
        {
            return _isSupported;
        }


        ///returns enabled status
        public boolean isEnabled()
        {
            return _isEnabled;
        }


        ///returns whether or not the sensor has received any data
        public boolean hasReceivedData()
        {
            return (_lastChangedTimestamp == 0) ? false : true;
        }


        ///handles enabling the sensor
        public boolean enable(boolean fromOnResume)
        {
            if(_isSupported && !_isEnabled)
            {
                ///if called from onResume, we need to check if we are supposed to resume this sensor
                if(!fromOnResume || _shouldResume)
                {
                    _shouldResume = false;
                    _isEnabled = _sensorManager.registerListener(this, _sensor, SensorManager.SENSOR_DELAY_GAME);
                    _isSupported = _isEnabled;
                }
            }
            return _isEnabled;
        }


        ///handles disabling the sensor
        public void disable(boolean fromOnPause)
        {
            if(_isSupported && _isEnabled)
            {
                _sensorManager.unregisterListener(this);
                _isEnabled = false;
                _shouldResume = fromOnPause;
            }
        }


        ///helper to remap the coordinate system for device orientation... NOTE: logic taken from the Cocos2dx Accelerometer code
        private float[] remapXYZValues(float[] xyz)
        {
            ///make copy of the array of incoming values
            float[] newValues = xyz.clone();

            ///Because the axes are not swapped when the device's screen orientation changes. 
            ///So we should swap it here.
            ///In some tablets such as Motorola Xoom, the default orientation is landscape, so should
            ///consider this.
            ///
            ///NOTE: My tests have shown that this may not be 100% correct... LL
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


        ///override for SensorEventListener.onSensorChanged
        @Override
        public void onSensorChanged(SensorEvent event)
        { 
            final float     dt = (_lastChangedTimestamp == 0) ? 0 : ((event.timestamp - _lastChangedTimestamp) * NS2S);
            float[]         remappedValues;
            float           x;
            float           y;
            float           z;


            ///handle type-specific data processing
            switch(event.sensor.getType())
            {
                case Sensor.TYPE_ACCELEROMETER:
                    ///if the sensor data is unreliable return
                    if(event.accuracy == SensorManager.SENSOR_STATUS_UNRELIABLE)
                    {
                        return;
                    }

                    ///get correctly oriented values to work with
                    remappedValues = remapXYZValues(event.values);
                    x = remappedValues[0];
                    y = remappedValues[1];
                    z = remappedValues[2];

                    ///register the change in native code
                    onAccelerometerChanged(x, y, z);
                    // Log.d(TAG, "Accelerometer Sensor Changed: x = " + x + " y = " + y + " z = " + z);
                    break;
                case Sensor.TYPE_MAGNETIC_FIELD:
                    ///get correctly oriented values to work with
                    remappedValues = remapXYZValues(event.values);
                    x = remappedValues[0];
                    y = remappedValues[1];
                    z = remappedValues[2];
 
                    ///register the change in native code
                    onMagnometerChanged(x, y, z);
                    // Log.d(TAG, "Magnometer Sensor Changed: x = " + x + " y = " + y + " z = " + z);
                    break;
                case Sensor.TYPE_GYROSCOPE:
                    ///if the sensor data is unreliable return
                    if(event.accuracy == SensorManager.SENSOR_STATUS_UNRELIABLE)
                    {
                        return;
                    }

                    ///get correctly oriented values to work with
                    remappedValues = remapXYZValues(event.values);
                    x = remappedValues[0];
                    y = remappedValues[1];
                    z = remappedValues[2];

                    ///register the change in native code
                    onGyroscopeChanged(x, y, z);
                    // Log.d(TAG, "Gyroscope Sensor Changed: x = " + x + " y = " + y + " z = " + z);
                    break;
                case Sensor.TYPE_ROTATION_VECTOR:
                    float[] r = new float[9];

                    ///get a rotation matrix from the current vector
                    SensorManager.getRotationMatrixFromVector(r, event.values);

                    ///possibly remap the rotation matrix based on our device orientation
                    int orientation = _context.getResources().getConfiguration().orientation;
                    if(_naturalOrientation != Surface.ROTATION_0)
                    {
                        float[]     tempR = new float[9];
                        if(orientation == Configuration.ORIENTATION_LANDSCAPE)
                        {
                            SensorManager.remapCoordinateSystem(r, SensorManager.AXIS_MINUS_Y, SensorManager.AXIS_X, tempR);
                            r = tempR;
                        }
                        else if(orientation == Configuration.ORIENTATION_PORTRAIT)
                        {
                            SensorManager.remapCoordinateSystem(r, SensorManager.AXIS_Y, SensorManager.AXIS_MINUS_X, tempR);
                            r = tempR;
                        }
                    }

                    ///update our orientation
                    float[] v = new float[3];
                    SensorManager.getOrientation(r, v);
                    // v[0]: azimuth, rotation around the Z axis. GROUND DOWN
                    // v[1]: pitch, rotation around the X axis. ROUGHLY WEST
                    // v[2]: roll, rotation around the Y axis. MAGNETIC NORTH
                    x = v[1];
                    y = v[2];
                    z = v[0];

                    ///wrap to 0 - 2*PI range
                    if(x < 0) x += (2 * Math.PI);
                    if(y < 0) y += (2 * Math.PI);
                    if(z < 0) z += (2 * Math.PI);

                    ///register the change in native code
                    onRotationChanged(x, y, z);
                    // Log.d(TAG, "Rotation Changed: x = " + x + " y = " + y + " z = " + z);
                    break;
            }

            ///store last changed time
            _lastChangedTimestamp = event.timestamp;
        }


        ///dummy stub override for SensorEventListener.onAccuracyChanged
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) 
        {
        }   
    }



    ///private vars
    private static final int                SENSOR_ACCELEROMETER    = 0;
    private static final int                SENSOR_MAGNOMETER       = 1;
    private static final int                SENSOR_GYROSCOPE        = 2;
    private static final int                SENSOR_ROTATION_VECTOR  = 3;
    private static final int                SENSOR_COUNT            = 4;

    private static final String             TAG = "Loom Sensors";

    private static Context                  _context;
    private static SensorManager            _sensorManager;
    private static int                      _naturalOrientation;
    private static AndroidSensor[]          _sensorList;



    ///handles initialization of the Loom Sensors class
    public static void onCreate(Activity context)
    {
        _context = context;

        //store sensor manager
        _sensorManager = (SensorManager)_context.getSystemService(Context.SENSOR_SERVICE);

        ///create sensors
        _sensorList = new AndroidSensor[SENSOR_COUNT];
        for(int i=0;i<SENSOR_COUNT;i++)
        {
            _sensorList[i] = new AndroidSensor(i);
        }

        ///store base orientation for internal calculations on our sensor values
        Display display = ((WindowManager)_context.getSystemService(Context.WINDOW_SERVICE)).getDefaultDisplay();
        _naturalOrientation = display.getOrientation();
    }


    ///handles destruction of the sensors
    public static void onDestroy()
    {
        for(int i=0;i<SENSOR_COUNT;i++)
        {
            _sensorList[i].disable(false);
        }
    }


    ///handles disabling sensors while the app is paused
    public static void onPause()
    {
        for(int i=0;i<SENSOR_COUNT;i++)
        {
            _sensorList[i].disable(true);
        }
    }


    ///handles enabling sensors while the app is resumed
    public static void onResume()
    {
        for(int i=0;i<SENSOR_COUNT;i++)
        {
            _sensorList[i].enable(true);
        }
    }


    ///checks if the specified sensor is supported
    public static boolean isSensorSupported(int sensorID)
    {
        if(sensorID < SENSOR_COUNT)
        {
            return _sensorList[sensorID].isSupported();
        }
        return false;
    }


    ///checks if the specified sensor is enabled
    public static boolean isSensorEnabled(int sensorID)
    {
        if(sensorID < SENSOR_COUNT)
        {
            return _sensorList[sensorID].isEnabled();
        }
        return false;
    }


    ///checks if the specified sensor has received any valid data
    public static boolean hasSensorReceivedData(int sensorID)
    {
        if(sensorID < SENSOR_COUNT)
        {
            return _sensorList[sensorID].hasReceivedData();
        }
        return false;
    }


    ///enables the specified sensor
    public static boolean enableSensor(int sensorID)
    {
        if(sensorID < SENSOR_COUNT)
        {
            return _sensorList[sensorID].enable(false);
        }
        return false;
    }


    ///disables the specified sensor
    public static void disableSensor(int sensorID)
    {
        if(sensorID < SENSOR_COUNT)
        {
            _sensorList[SENSOR_ACCELEROMETER].disable(false);
        }
    }


    ///calls the native delegate for device accelerometer changing
    private static void onAccelerometerChanged(float x, float y, float z)
    {
        ///NOTE: Don't use Accelerometer for now...
    }


    ///calls the native delegate for device magnometer changing
    private static void onMagnometerChanged(float x, float y, float z)
    {
        ///NOTE: Don't use Magnometer for now...
    }


    ///calls the native delegate for device gyroscope changing
    private static void onGyroscopeChanged(float x, float y, float z)
    {
        ///NOTE: Don't use Gyroscope for now...
    }

    ///calls the native delegate for device rotation changing
    private static void onRotationChanged(float x, float y, float z)
    {
        final float fX = x;
        final float fY = y;
        final float fZ = z;

        ///make sure to call the delegate in the main thread
        Cocos2dxGLSurfaceView.mainView.queueEvent(new Runnable() 
        {
            @Override
            public void run() 
            {
                onRotationChangedNative(fX, fY, fZ);
            }
        });
    }

    ///native delegate stubs
    private static native void onRotationChangedNative(float x, float y, float z);
    // private static native void onAccelerometerChanged(float x, float y, float z);
    // private static native void onMagnometerChanged(float x, float y, float z);
    // private static native void onGyroscopeChanged(float x, float y, float z);
}
