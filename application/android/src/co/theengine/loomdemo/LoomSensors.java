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
                    _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);
                    _type = "Magnometer";
                    break;
                case SENSOR_GYROSCOPE:
                    _sensor = _sensorManager.getDefaultSensor(Sensor.TYPE_GYROSCOPE);
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


static float _printTimer = 0.0f;
        ///override for SensorEventListener.onSensorChanged
        @Override
        public void onSensorChanged(SensorEvent event)
        { 
            final float     dt = (_lastChangedTimestamp == 0) ? 0 : ((event.timestamp - _lastChangedTimestamp) * NS2S);
            boolean         updateRotation = false;
            boolean         updateOrientation = false;
            float[]         r = new float[9];
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

                    ///store updated values to calculate our orientation with
                    _lastAccelerometerValues = remappedValues;
                    updateRotation = true;

                    ///register the change in native code
                    onAccelerometerChanged(x, y, z, event.timestamp);
                    // Log.d(TAG, "Accelerometer Sensor Changed: x = " + x + " y = " + y + " z = " + z);
                    break;
                case Sensor.TYPE_MAGNETIC_FIELD:
                    ///get correctly oriented values to work with
                    remappedValues = remapXYZValues(event.values);
                    x = remappedValues[0];
                    y = remappedValues[1];
                    z = remappedValues[2];

                    ///store updated values to calculate our orientation with
                    _lastMagnometerValues = remappedValues;
                    updateRotation = true;
 
                    ///register the change in native code
                    onMagnometerChanged(x, y, z, event.timestamp);
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
/*
                    ///set new current orientation matrix by combining this latest delta to it
                    if(false)//dt != 0)
                    {
                        ///Axis of the rotation sample, not normalized yet.
                        float   axisX = x;//event.values[0];
                        float   axisY = y;//event.values[1];
                        float   axisZ = z;//event.values[2];

                        ///Calculate the angular speed of the sample & normalize the rotation
                        float   omegaMagnitude = (float)Math.sqrt((axisX * axisX) + (axisY * axisY) + (axisZ * axisZ));
                        if (omegaMagnitude > 1e-4) 
                        {
                            float   invOmegaMagnitude = 1.0f / omegaMagnitude;
                            axisX *= invOmegaMagnitude;
                            axisY *= invOmegaMagnitude;
                            axisZ *= invOmegaMagnitude;
                        }

                        ///Integrate around this axis with the angular speed by the timestep
                        ///in order to get a delta rotation from this sample over the timestep
                        ///We will convert this axis-angle representation of the delta rotation
                        ///into a quaternion before turning it into the rotation matrix.
                        final float[]   deltaRotationVector = new float[3];//4];
                        float           thetaOverTwo = omegaMagnitude * dt * 0.5f;
                        float           sinThetaOverTwo = (float)Math.sin(thetaOverTwo);
                        float           cosThetaOverTwo = (float)Math.cos(thetaOverTwo);
                        deltaRotationVector[0] = sinThetaOverTwo * axisX;
                        deltaRotationVector[1] = sinThetaOverTwo * axisY;
                        deltaRotationVector[2] = sinThetaOverTwo * axisZ;
                        // deltaRotationVector[3] = cosThetaOverTwo;

                        ///get current rotation delta to use
                        float[]   deltaRotationMatrix = new float[9];
                        SensorManager.getRotationMatrixFromVector(deltaRotationMatrix, deltaRotationVector);
                         
                        ///concactenate the delta rotation into the current rotation
                        Matrix  updatedMatrix = new Matrix();
                        updatedMatrix.setValues(deltaRotationMatrix);
                        _currentRotation.preConcat(updatedMatrix);
                        _currentRotation.getValues(r);
                        updateOrientation = true;
                    }
*/
                    ///register the change in native code
                    onGyroscopeChanged(x, y, z, event.timestamp);
                    // Log.d(TAG, "Gyroscope Sensor Changed: x = " + x + " y = " + y + " z = " + z);
                    break;
                case Sensor.TYPE_ROTATION_VECTOR:
_printTimer += dt;

                    ///get a rotation matrix from the current vector
                    SensorManager.getRotationMatrixFromVector(r, event.values);

                    ///possibly remap the rotation matrix based on our device orientation
                    int orientation = _context.getResources().getConfiguration().orientation;
                    if(_naturalOrientation != Surface.ROTATION_0)
                    {
                        float[]     tempR = new float[9];
                        if(orientation == Configuration.ORIENTATION_LANDSCAPE)
                        {
if(_printTimer > 2.0f)
Log.d(TAG, "ORIENTATION REMAP LANDSCAPE: " + _naturalOrientation);
                            SensorManager.remapCoordinateSystem(r, SensorManager.AXIS_MINUS_Y, SensorManager.AXIS_X, tempR);
                            r = tempR;
                        }
                        else if(orientation == Configuration.ORIENTATION_PORTRAIT)
                        {
if(_printTimer > 2.0f)
Log.d(TAG, "ORIENTATION REMAP PORTRAIT: " + _naturalOrientation);
                            SensorManager.remapCoordinateSystem(r, SensorManager.AXIS_Y, SensorManager.AXIS_MINUS_X, tempR);
                            r = tempR;
                        }
                    }

                    _currentRotation.setValues(r);
                    updateOrientation = true;
                    break;
                default:
                    return;
            }

/*
            ///update our rotation matrix from accelerometer & magnometer?
            if(updateRotation && (_lastAccelerometerValues != null) && (_lastMagnometerValues != null))
            {
                ///if we have a gyroscope enabled, we would rather use that!
                if(!isGyroscopeEnabled())
                {
                    boolean success = SensorManager.getRotationMatrix(r, null, _lastAccelerometerValues, _lastMagnometerValues);
                    if(success)
                    {
                        updateOrientation = true;
                    }
                }
            }
*/
            ///update orientation from our rotation?
            if(updateOrientation)
            {
///////////
//-Using the camera (Y axis along the camera's axis) for an augmented reality application where the rotation angles are needed:
//  remapCoordinateSystem(inR, AXIS_X, AXIS_Z, outR);
//-Using the device as a mechanical compass when rotation is Surface.ROTATION_90:
//  remapCoordinateSystem(inR, AXIS_Y, AXIS_MINUS_X, outR);
///////////
                ///update our orientation
                float[] v = new float[3];
                SensorManager.getOrientation(r, v);
                // v[0]: azimuth, rotation around the Z axis. GROUND DOWN
                // v[1]: pitch, rotation around the X axis. ROUGHLY WEST
                // v[2]: roll, rotation around the Y axis. MAGNETIC NORTH
                x = v[1];
                y = v[2];
                z = v[0];

                ///register the change in native code
                onOrientationChanged(x, y, z, event.timestamp);

if(_printTimer > 2.0f)
{
    _printTimer = 0.0f;                
    x *= (float)(180.0f / Math.PI);
    y *= (float)(180.0f / Math.PI);
    z *= (float)(180.0f / Math.PI);
    if(x < 0) x += 360.0f;
    if(y < 0) y += 360.0f;
    if(z < 0) z += 360.0f;
    Log.d(TAG, "************************ ** ** ** ** ** Orientation Changed: x = " + x + " y = " + y + " z = " + z);
}
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
    private static final String             TAG = "Loom Sensors";
    private static final int                SENSOR_ACCELEROMETER = 0;
    private static final int                SENSOR_MAGNOMETER = 1;
    private static final int                SENSOR_GYROSCOPE = 2;
    private static final int                SENSOR_ROTATION_VECTOR = 3;
    private static final int                SENSOR_COUNT = 4;

    private static Context                  _context;
    private static SensorManager            _sensorManager;
    private static int                      _naturalOrientation;
    private static AndroidSensor[]          _sensorList;
    private static Matrix                   _currentRotation;
    private static float[]                  _lastAccelerometerValues;
    private static float[]                  _lastMagnometerValues;



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

        ///clear orientation data
        resetOrientation();

///TEMP TEST CODE to enable all sensors by default at the start        
for(int i=0;i<SENSOR_COUNT;i++)
{
    _sensorList[i].enable(false);
}
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


public static boolean isAccelerometerSupported()
{
    return _sensorList[SENSOR_ACCELEROMETER].isSupported();
}
public static boolean isAccelerometerEnabled()
{
    return _sensorList[SENSOR_ACCELEROMETER].isEnabled();
}
public static boolean enableAccelerometer()
{
    return _sensorList[SENSOR_ACCELEROMETER].enable(false);
}
public static void disbleAccelerometer()
{
    _sensorList[SENSOR_ACCELEROMETER].disable(false);
}
public static boolean isMagnometerSupported()
{
    return _sensorList[SENSOR_MAGNOMETER].isSupported();
}
public static boolean isMagnometerEnabled()
{
    return _sensorList[SENSOR_MAGNOMETER].isEnabled();
}
public static boolean enableMagnometer()
{
    return _sensorList[SENSOR_MAGNOMETER].enable(false);
}
public static void disbleMagnometer()
{
    _sensorList[SENSOR_MAGNOMETER].disable(false);
}
public static boolean isGyroscopeSupported()
{
    return _sensorList[SENSOR_GYROSCOPE].isSupported();
}
public static boolean isGyroscopeEnabled()
{
    return _sensorList[SENSOR_GYROSCOPE].isEnabled();
}
public static boolean enableGyroscope()
{
    return _sensorList[SENSOR_GYROSCOPE].enable(false);
}
public static void disableGyroscope()
{
    _sensorList[SENSOR_GYROSCOPE].disable(false);
}
public static void resetOrientation()
{
    ///create identity rotation matrix to start with
    _currentRotation = new Matrix();
    _lastAccelerometerValues = null;
    _lastMagnometerValues = null;
    _sensorList[SENSOR_GYROSCOPE]._lastChangedTimestamp = 0;
}

 
    ///native function stubs
    // private static native void onAccelerometerChanged(float x, float y, float z, long timeStamp);
    // private static native void onMagnometerChanged(float x, float y, float z, long timeStamp);
    // private static native void onGyroscopeChanged(float x, float y, float z, long timeStamp);
    // private static native void onOrientationChanged(float x, float y, float z, long timeStamp);
    private static void onAccelerometerChanged(float x, float y, float z, long timeStamp){}
    private static void onMagnometerChanged(float x, float y, float z, long timeStamp){}
    private static void onGyroscopeChanged(float x, float y, float z, long timeStamp){}
    private static void onOrientationChanged(float x, float y, float z, long timeStamp){}
}
