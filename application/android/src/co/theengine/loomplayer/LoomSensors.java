package co.theengine.loomplayer;


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




/**
 * 
 * This class is used for accessing the various Android Sensors
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
                    _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
                    _type = "Accelerometer";
                    break;
                case SENSOR_MAGNOMETER:
                    ///NOTE: Don't use Magnometer for now...
                    // _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
                    Log.w(TAG, "SENSOR_MAGNOMETER support not supported at the moment.");
                    _type = "Magnometer";
                    break;
                case SENSOR_GYROSCOPE:
                    ///NOTE: Don't use Gyroscope for now...
                    // _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
                    Log.w(TAG, "SENSOR_GYROSCOPE support not supported at the moment.");
                    _type = "Gyroscope";
                    break;
                case SENSOR_ROTATION_VECTOR:
                    ///NOTE: Only supported in Api 9+ (Gingerbread 2.3)
                    _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR);
                    _type = "Rotation Vector";
                    break;
                case SENSOR_GRAVITY:
                    ///NOTE: Only supported in Api 9+ (Gingerbread 2.3)
                    _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_GRAVITY);
                    _type = "Gravity";
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
                _sensorManager.unregisterListener(this, _sensor);
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
            int curOrientation = _context.getResources().getConfiguration().orientation;
            if(_naturalRotation != Surface.ROTATION_0)
            {
                if(curOrientation == Configuration.ORIENTATION_LANDSCAPE)
                {
                    float tmp = newValues[0];
                    newValues[0] = -newValues[1];
                    newValues[1] = tmp;
                }
                else if(curOrientation == Configuration.ORIENTATION_PORTRAIT)
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

                    //normalize the values
                    x = - remappedValues[0] / SensorManager.GRAVITY_EARTH;
                    y = - remappedValues[1] / SensorManager.GRAVITY_EARTH;
                    z = - remappedValues[2] / SensorManager.GRAVITY_EARTH;

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
                    int     curOrientation = _context.getResources().getConfiguration().orientation;
                    float[] v = new float[3];
                    float[] r = new float[9];
                    float[] tempR = new float[9];

                    ///get a rotation matrix from the current vector
                    SensorManager.getRotationMatrixFromVector(r, event.values);

                    ///possibly remap the rotation matrix based on our device orientation
                    switch(_naturalRotation)
                    {
                        case Surface.ROTATION_0:
                            ///do nothing
                            break;
                        case Surface.ROTATION_90:
                            ///rotate 90 degrees clockwise around Z
                            SensorManager.remapCoordinateSystem(r, SensorManager.AXIS_Y, SensorManager.AXIS_MINUS_X, tempR);
                            r = tempR;
                            break;
                        case Surface.ROTATION_180:
                            ///rotate 180 degrees around Z
                            SensorManager.remapCoordinateSystem(r, SensorManager.AXIS_MINUS_X, SensorManager.AXIS_MINUS_Y, tempR);
                            r = tempR;
                            break;
                        case Surface.ROTATION_270:
                            ///rotate 90 degrees counter-clockwise around Z
                            SensorManager.remapCoordinateSystem(r, SensorManager.AXIS_MINUS_Y, SensorManager.AXIS_X, tempR);
                            r = tempR;
                            break;
                    }
                    
                    ///update our device orientation
                    SensorManager.getOrientation(r, v);
                    x = v[1];   // v[1]: pitch, rotation around the X axis
                    y = v[2];   // v[2]: roll, rotation around the Y axis
                    z = v[0];   // v[0]: azimuth, rotation around the Z axis

                    ///NOTE: Galaxy S2 appears to have the azimuth defined in -PI/2 <--> PI/2 range!!! :(
                    ///         Don't think there is anything we can do to figure this out unfortunately :(

                    ///negate the x to get the coordinate system that we want
                    x *= -1.0f;

                    ///register the change in native code
                    onRotationChanged(x, y, z);
                    // Log.d(TAG, "Rotation Changed: x = " + x + " y = " + y + " z = " + z);
                    break;
                case Sensor.TYPE_GRAVITY:
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
                    onGravityChanged(x, y, z);
                    // Log.d(TAG, "Gravity Sensor Changed: x = " + x + " y = " + y + " z = " + z);
                    break;
           }

            ///store last changed time
            _lastChangedTimestamp = event.timestamp;
        }


        ///dummy stub override for SensorEventListener.onAccuracyChanged
        @Override
        public void onAccuracyChanged(Sensor sensor, int accuracy) 
        {
            ///nothing to do here really... just need the stub for SensorEventListener to compile
        }   
    }



    ///private vars
    private static final int                SENSOR_ACCELEROMETER    = 0;
    private static final int                SENSOR_MAGNOMETER       = 1;
    private static final int                SENSOR_GYROSCOPE        = 2;
    private static final int                SENSOR_ROTATION_VECTOR  = 3;
    private static final int                SENSOR_GRAVITY          = 4;
    private static final int                SENSOR_COUNT            = 5;

    private static final String             TAG = "Loom Sensors";

    private static Context                  _context;
    private static Activity                 activity;
    private static SensorManager            _sensorManager;
    private static int                      _naturalRotation;
    private static AndroidSensor[]          _sensorList;



    ///handles initialization of the Loom Sensors class
    public static void onCreate(Activity context)
    {
        _context = context;
        activity = LoomAdMob.activity;

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
        _naturalRotation = display.getOrientation();
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
            _sensorList[sensorID].disable(false);
        }
    }


    ///calls the native delegate for device accelerometer changing
    private static void onAccelerometerChanged(float x, float y, float z)
    {
        final float fX = x;
        final float fY = y;
        final float fZ = z;

        ///make sure to call the delegate in the main thread
        // TODO: does this require queueEvent?
        activity.runOnUiThread(new Runnable()
        {
            @Override
            public void run()
            {
                onAccelerometerChangedNative(fX, fY, fZ);
            }
        });
    }


    ///calls the native delegate for device magnometer changing
    private static void onMagnometerChanged(float x, float y, float z)
    {
        ///NOTE: Don't use Magnometer for now... if implemented at some point, follow code used in 'onRotationChanged()'
    }


    ///calls the native delegate for device gyroscope changing
    private static void onGyroscopeChanged(float x, float y, float z)
    {
        ///NOTE: Don't use Gyroscope for now... if implemented at some point, follow code used in 'onRotationChanged()'
    }


    ///calls the native delegate for device rotation changing
    private static void onRotationChanged(float x, float y, float z)
    {
        final float fX = x;
        final float fY = y;
        final float fZ = z;

        ///make sure to call the delegate in the main thread
        // TODO: does this require queueEvent?
        activity.runOnUiThread(new Runnable()
        {
            @Override
            public void run()
            {
                onRotationChangedNative(fX, fY, fZ);
            }
        });
    }

    ///calls the native delegate for device gravity changing
    private static void onGravityChanged(float x, float y, float z)
    {
        final float fX = x;
        final float fY = y;
        final float fZ = z;

        ///make sure to call the delegate in the main thread
        // TODO: does this require queueEvent?
        activity.runOnUiThread(new Runnable()
        {
            @Override
            public void run()
            {
                onGravityChangedNative(fX, fY, fZ);
            }
        });
    }

    ///native delegate stubs
    private static native void onRotationChangedNative(float x, float y, float z);
    private static native void onGravityChangedNative(float x, float y, float z);
    private static native void onAccelerometerChangedNative(float x, float y, float z);
    // private static native void onMagnometerChanged(float x, float y, float z);
    // private static native void onGyroscopeChanged(float x, float y, float z);
}
