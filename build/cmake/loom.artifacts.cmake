
# This file generates the build artifacts when invoking cmake outside of rake
# Currently, APPLE builds are supported


if (APPLE) 

	get_target_property(APPLICATION_BIN ${APPLICATION_NAME} LOCATION)
	get_dotapp_dir(${APPLICATION_BIN} APPLICATION_APP_LOCATION)
	
	set(RSYNC_CMD rsync -a --delete)
	
	if(LOOM_BUILD_IOS EQUAL 1)
		add_custom_target(CreateIOSArtifact ALL
		    COMMAND ${RSYNC_CMD} ${CMAKE_SOURCE_DIR}/sdk/assets ${APPLICATION_APP_LOCATION}
		    COMMAND ${RSYNC_CMD} ${CMAKE_SOURCE_DIR}/sdk/bin  ${APPLICATION_APP_LOCATION}
		    COMMAND ${RSYNC_CMD} ${CMAKE_SOURCE_DIR}/sdk/libs  ${APPLICATION_APP_LOCATION}
		    COMMAND mkdir -p ${CMAKE_SOURCE_DIR}/artifacts/ios/
		    COMMAND ${RSYNC_CMD} ${APPLICATION_APP_LOCATION} ${CMAKE_SOURCE_DIR}/artifacts/ios/
		)
		add_dependencies(CreateIOSArtifact ${APPLICATION_NAME} lsc)
	else()
	
		add_custom_target(CreateOSXArtifact ALL
	    	COMMAND ${CMAKE_SOURCE_DIR}/artifacts/lsc --root ${CMAKE_SOURCE_DIR}/sdk Main.build
		    COMMAND ${RSYNC_CMD} ${CMAKE_SOURCE_DIR}/sdk/assets ${APPLICATION_APP_LOCATION}/Contents/Resources
		    COMMAND ${RSYNC_CMD} ${CMAKE_SOURCE_DIR}/sdk/bin  ${APPLICATION_APP_LOCATION}/Contents/Resources
		    COMMAND ${RSYNC_CMD} ${CMAKE_SOURCE_DIR}/sdk/libs  ${APPLICATION_APP_LOCATION}/Contents/Resources
		    COMMAND mkdir -p ${CMAKE_SOURCE_DIR}/artifacts/osx/
		    COMMAND ${RSYNC_CMD} ${APPLICATION_APP_LOCATION} ${CMAKE_SOURCE_DIR}/artifacts/osx/
		)
		
		add_dependencies(CreateOSXArtifact ${APPLICATION_NAME} lsc)
	
	endif()	

endif(APPLE)
