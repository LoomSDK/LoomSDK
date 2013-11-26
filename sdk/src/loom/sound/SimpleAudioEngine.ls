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
     * A VERY simple interface to play background music & sound effects.
     *
     * This is implemented on top of Sound and Listener to allow easy sound
     * playback. Sometimes you just want to play a sound!
     *
     * @see Sound
     * @see Listener
     */
    public class SimpleAudioEngine
    {
        // TODO: Disallow explicit creation of this class.

        protected static var _sharedInstance:SimpleAudioEngine = null;

        protected var backgroundMusic:Sound;
        protected var sounds = new Vector.<Sound>();


        /**
        Get the shared Engine object,it will new one when first time be called
        */
        public static function sharedEngine():SimpleAudioEngine
        {
            if(!_sharedInstance)
                _sharedInstance = new SimpleAudioEngine();
            return _sharedInstance;
        }

        /**
        Release the shared Engine object
        @warning It must be called before the application exit, or a memroy leak will be casued.
        */
        public static function end():void
        {
            sharedEngine().stopBackgroundMusic(false);
        }

        /**
        Preload background music
        @param pszFilePath The path of the background music file,or the FileName of T_SoundResInfo
        */
        public function preloadBackgroundMusic(path:String):void
        {
            var s = Sound.load(path);
            if(s)
                s.deleteNative();
        }

        /**
        Play background music
        @param pszFilePath The path of the background music file,or the FileName of T_SoundResInfo
        @param bLoop Whether the background music loop or not
        */
        public function playBackgroundMusic(path:String, loop:Boolean = true):void
        {
            stopBackgroundMusic(false);
            if(backgroundMusic)
                backgroundMusic.deleteNative();
            backgroundMusic = Sound.load(path);
            backgroundMusic.setLooping(loop);
            backgroundMusic.play();
        }

        /**
        Stop playing background music
        @param release If release the background music data or not. As default value is false
        */
        public function stopBackgroundMusic(release:Boolean):void
        {
            if(backgroundMusic)
                backgroundMusic.stop();
        }

        /**
        Pause playing background music
        */
        public function pauseBackgroundMusic():void
        {
            if(backgroundMusic)
                backgroundMusic.pause();            
        }

        /**
        Resume playing background music
        */
        public function resumeBackgroundMusic():void
        {
            if(backgroundMusic)
                backgroundMusic.play();
        }

        /**
        Rewind playing background music
        */
        public function rewindBackgroundMusic():void
        {
            if(backgroundMusic)
                backgroundMusic.rewind();            
        }

        public function willPlayBackgroundMusic():Boolean
        {
            return backgroundMusic != null;
        }

        /**
        Whether the background music is playing
        @return If is playing return true,or return false
        */
        public function isBackgroundMusicPlaying():Boolean
        {
            return backgroundMusic.isPlaying();            
        }

        /**
        The volume of the background music max value is 1.0,the min value is 0.0
        */
        public function getBackgroundMusicVolume():Number
        {
            if(backgroundMusic == null)
                return 1;
            return backgroundMusic.getGain();            
        }

        /**
        set the volume of background music
        @param volume must be in 0.0~1.0
        */
        public function setBackgroundMusicVolume(volume:Number):void
        {
            if(backgroundMusic)
                backgroundMusic.setGain(volume);
        }

        /**
        The volume of the effects max value is 1.0,the min value is 0.0
        */
        public function getEffectsVolume():Number
        {
            return 1.0;
        }

        /**
        set the volume of sound effecs
        @param volume must be in 0.0~1.0
        */
        public function setEffectsVolume(volume:Number):void
        {
            trace("WARNING: SimpleAudioEngine.setEffectsVolume is not implemented. See loom.sound.Listener.");
        }

        /**
        Play sound effect
        @param filePath The path of the effect file,or the FileName of T_SoundResInfo
        @param loop Whether to loop the effect playing, default value is false
        */
        public function playEffect(path:String, loop:Boolean = false):int
        {
            var s = Sound.load(path);
            if(!s)
                return -1;
            s.setLooping(loop);
            s.play();
            sounds.push(s);
            return sounds.length - 1;
        }

        /**
        Pause playing sound effect
        @param soundId The return value of function playEffect
        */
        public function pauseEffect(soundId:int):void
        {
            sounds[soundId].pause();
        }

        /**
        Pause all playing sound effect
        */
        public function pauseAllEffects():void
        {
            for(var i=0; i<sounds.length; i++)
                sounds[i].pause();
        }

        /**
        Resume playing sound effect
        @param soundId The return value of function playEffect
        */
        public function resumeEffect(soundId:int):void
        {
            sounds[soundId].play();
        }

        /**
        Resume all playing sound effect
        */
        public function resumeAllEffects():void
        {
            for(var i=0; i<sounds.length; i++)
                sounds[i].play();
        }

        /**
        Stop playing sound effect
        @param soundId The return value of function playEffect
        */
        public function stopEffect(soundId:int):void
        {
            sounds[soundId].stop();
        }

        /**
        Stop all playing sound effects
        */
        public function stopAllEffects():void
        {
            for(var i=0; i<sounds.length; i++)
                sounds[i].stop();
        }

        /**
         preload an audio file for quicker playback.
        */
        public function preloadEffect(path:String):void
        {
            var s = Sound.load(path);
            if(s)
                s.deleteNative();
        }

        /**
                 unload the preloaded effect from internal buffer
        @param        pszFilePath        The path of the effect file,or the FileName of T_SoundResInfo
        */
        public function unloadEffect(path:string):void
        {
            // TODO
        }
    }
}