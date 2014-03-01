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
        protected static var _sharedInstance:SimpleAudioEngine = null;
        protected static var _allowInstantiation:Boolean = false;

        protected var backgroundMusic:Sound;
        protected var sounds = new Vector.<Sound>();
        protected var pausedEffects = new Vector.<Sound>();
        protected var soundIdLookup:Dictionary.<Object, Object> = {};
        protected var lastSoundId:int = -1;

        public function SimpleAudioEngine()
        {
            Debug.assert( _allowInstantiation, "SimpleAudioEngine cannot be instantiated directly. Please use SimpleAudioEngine.sharedEngine() to access the appropriate instance." );
        }

        /**
        Get the shared Engine object,it will new one when first time be called
        */
        public static function sharedEngine():SimpleAudioEngine
        {
            if(!_sharedInstance)
            {
                _allowInstantiation = true;
                _sharedInstance = new SimpleAudioEngine();
                _allowInstantiation = false;
            }
            return _sharedInstance;
        }

        /**
        Release the shared Engine object
        @warning It must be called before the application exit, or a memory leak will be caused.
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

            lastSoundId++;

            s.setLooping(loop);
            s.play();

            // Loop through all sounds in the Vector. If a sound is found that is done playing, remove it.
            // Our sound vector should never contain more sounds than were simultaneously playing at one point.

            var soundCount:int = sounds.length;
            var i:int = 0;
            while ( i < soundCount )
            {
                var sound:Sound = sounds[ i ];
                if ( !sound ) break;
                else if ( !sound.isPlaying() )
                {
                    removeSound( sound );
                    break;
                }
                i++;
            }

            // If we removed a used sound from the vector, use its slot for the new sound. Otherwise create a new slot.
            if ( i < soundCount ) sounds[ i ] = s;
            else sounds.pushSingle( s );

            // Add our new sound ID to our double lookup table. This ensures a unique ID for every sound.
            soundIdLookup[ lastSoundId ] = s;
            soundIdLookup[ s ] = lastSoundId;

            //trace( "Last sound ID:", lastSoundId, "::", "Total sounds in vector:", sounds.length, "::", "Total paused Sounds:", pausedEffects.length );

            return lastSoundId;
        }

        /**
        Pause playing sound effect
        @param soundId The return value of function playEffect
        */
        public function pauseEffect(soundId:int):void
        {
            var sound = getSoundById( soundId );
            if ( sound )
            {
                 sound.pause();
                 var soundIndex:int = sounds.indexOf( sound );
                 sounds[ soundIndex ] = null;
                 pausedEffects.pushSingle( sound );
            }
        }

        /**
        Pause all playing sound effect
        */
        public function pauseAllEffects():void
        {
            var soundCount:int = sounds.length;
            for ( var i:int = 0; i < soundCount; i++ )
            {
                var sound = sounds[ i ];
                if ( sound )
                {
                    sound.pause();
                    pausedEffects.pushSingle( sound );
                    sounds[i] = null;
                }
            }
        }

        /**
        Resume playing sound effect
        @param soundId The return value of function playEffect
        */
        public function resumeEffect(soundId:int):void
        {
            var sound = getSoundById( soundId );
            var soundIndex = -1;
            if ( sound ) soundIndex = pausedEffects.indexOf( sound );
            if ( soundIndex != -1 )
            {
                sound.play();
                mergeSoundsWithActiveList( pausedEffects.splice( soundIndex, 1 ) );
            }
        }

        /**
        Resume all playing sound effect
        */
        public function resumeAllEffects():void
        {
            var soundCount:int = pausedEffects.length;
            if ( soundCount == 0 ) return;
            for ( var i:int = 0; i < soundCount; i++ ) pausedEffects[ i ].play();
            mergeSoundsWithActiveList( pausedEffects );
            pausedEffects.clear();
        }

        /**
        Stop playing sound effect
        @param soundId The return value of function playEffect
        */
        public function stopEffect( soundId:int ):void
        {
            var sound = getSoundById( soundId );
            if ( !sound ) return;

            sound.stop();

            var soundIndex = sounds.indexOf( sound );
            if ( soundIndex != -1 )
            {
                sounds[ soundIndex ] = null;
            }
            else
            {
                soundIndex = pausedEffects.indexOf( sound );
                if ( soundIndex != -1 ) pausedEffects.splice( soundIndex, 1 );
            }

            removeSound( sound );
        }

        /**
        Stop all playing sound effects
        */
        public function stopAllEffects():void
        {
            var combinedSounds:Vector.<Sound> = sounds.concat( pausedEffects );
            var combinedSoundCount:int = 0;

            for ( var i:int = 0; i < combinedSoundCount; i++ )
            {
                combinedSounds[ i ].stop();
                removeSound( combinedSounds[ i ] );
            }
            
            combinedSounds.clear();
            sounds.clear();
            pausedEffects.clear();
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

        public function getSoundById( soundId:int ):Sound
        {
            var sound:Sound = soundIdLookup[ soundId ] as Sound;
            return sound;
        }

        private function mergeSoundsWithActiveList( mergeList:Vector.<Sound> ):void
        {
            var masterSoundCount:int = sounds.length;
            var mergeSoundCount:int = mergeList.length;
            var masterIndex:int = 0;

            for ( var i:int = 0; i < mergeSoundCount; i++ )
            {
                while( masterIndex < masterSoundCount && sounds[ masterIndex ] && sounds[ masterIndex ].isPlaying() ) masterIndex++;

                if ( masterIndex >= masterSoundCount )
                {
                    sounds = sounds.concat( mergeList.slice( i ) );
                    return;
                }

                if ( sounds[ masterIndex ] ) removeSound( sounds[ masterIndex ] );
                sounds[ masterIndex ] = mergeList[ i ];
            }
        }

        private function removeSound( sound:Sound ):void
        {
            var soundId:int = soundIdLookup[ sound ] as int;
            soundIdLookup[ sound ] = null;
            soundIdLookup[ soundId ] = null;
            sound.deleteNative();
        }
    }
}