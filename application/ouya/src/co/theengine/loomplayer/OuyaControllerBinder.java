package co.theengine.loomplayer;

import tv.ouya.console.api.OuyaController;
import android.util.Log;
import android.view.KeyEvent;
import android.view.MotionEvent;

/**
 * 
 * A very simple binder class used to query the Ouya controller from native code
 *
 */
public class OuyaControllerBinder
{

	public static float getControllerAxisValue(int playerNum, int ouyaAxis)
	{
		try
		{
			OuyaController controller = OuyaController.getControllerByPlayer(playerNum);

			if (controller == null)
			{
				return 0;
			}
			
			return controller.getAxisValue(ouyaAxis);			
		}
		catch(Exception e)
		{
			return 0.f;
		}
	}

	public static boolean getControllerButton(int playerNum, int ouyaButton)
	{
		try
		{
			OuyaController controller = OuyaController.getControllerByPlayer(playerNum);

			if (controller == null)
			{
				return false;
			}
			
			return controller.getButton(ouyaButton);			
		}
		catch(Exception e)
		{
			return false;
		}
	}


}