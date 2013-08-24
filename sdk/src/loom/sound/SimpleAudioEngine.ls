/*
===========================================================================
Loom SDK
Copyright 2011, 2012, 2013 
The Game Engine Company, LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 
===========================================================================
*/

package loom.sound
{
   /**
   @class          SimpleAudioEngine
   @brief          offer a VERY simple interface to play background music & sound effect
   */
	public native class SimpleAudioEngine
	{
		// TODO: Disallow explicit creation of this class.

      /**
      @brief Get the shared Engine object,it will new one when first time be called
      */
		public static native function sharedEngine():SimpleAudioEngine;

      /**
      @brief Release the shared Engine object
      @warning It must be called before the application exit, or a memroy leak will be casued.
      */
		public static native function end():void;

      /**
       @brief Preload background music
       @param pszFilePath The path of the background music file,or the FileName of T_SoundResInfo
       */
		public native function preloadBackgroundMusic(path:String):void;

      /**
      @brief Play background music
      @param pszFilePath The path of the background music file,or the FileName of T_SoundResInfo
      @param bLoop Whether the background music loop or not
      */
		public native function playBackgroundMusic(path:String, loop:Boolean = true):void;

      /**
      @brief Stop playing background music
      @param bReleaseData If release the background music data or not.As default value is false
      */
		public native function stopBackgroundMusic(release:Boolean):void;
		
      /**
      @brief Pause playing background music
      */
      public native function pauseBackgroundMusic():void;
		
      /**
      @brief Resume playing background music
      */
      public native function resumeBackgroundMusic():void;
		
      /**
      @brief Rewind playing background music
      */
      public native function rewindBackgroundMusic():void;
		
      public native function willPlayBackgroundMusic():Boolean;
		
      /**
      @brief Whether the background music is playing
      @return If is playing return true,or return false
      */
      public native function isBackgroundMusicPlaying():Boolean;
		
      /**
      @brief The volume of the background music max value is 1.0,the min value is 0.0
      */
      public native function getBackgroundMusicVolume():Number;
		
      /**
      @brief set the volume of background music
      @param volume must be in 0.0~1.0
      */
      public native function setBackgroundMusicVolume(volume:Number):void;
		
      /**
      @brief The volume of the effects max value is 1.0,the min value is 0.0
      */
      public native function getEffectsVolume():Number;
		
      /**
      @brief set the volume of sound effecs
      @param volume must be in 0.0~1.0
      */
      public native function setEffectsVolume(volume:Number):void;
		
      /**
      @brief Play sound effect
      @param pszFilePath The path of the effect file,or the FileName of T_SoundResInfo
      @bLoop Whether to loop the effect playing, default value is false
      */
      public native function playEffect(path:String, loop:Boolean = false):int;
		
      /**
      @brief Pause playing sound effect
      @param nSoundId The return value of function playEffect
      */
      public native function pauseEffect(soundId:int):void;
		
      /**
      @brief Pause all playing sound effect
      */
      public native function pauseAllEffects():void;
		
      /**
      @brief Resume playing sound effect
      @param nSoundId The return value of function playEffect
      */
      public native function resumeEffect(soundId:int):void;
		
      /**
      @brief Resume all playing sound effect
      */
      public native function resumeAllEffects():void;
		
      /**
      @brief Stop playing sound effect
      @param nSoundId The return value of function playEffect
      */
      public native function stopEffect(soundId:int):void;
		
      /**
      @brief Stop all playing sound effects
      */
      public native function stopAllEffects():void;
		
      /**
      @brief          preload a compressed audio file
      @details        the compressed audio will be decode to wave, then write into an 
      internal buffer in SimpleaudioEngine
      */
      public native function preloadEffect(path:String):void;
		
      /**
      @brief          unload the preloaded effect from internal buffer
      @param[in]        pszFilePath        The path of the effect file,or the FileName of T_SoundResInfo
      */
      public native function unloadEffect(path:string):void;
	}
}