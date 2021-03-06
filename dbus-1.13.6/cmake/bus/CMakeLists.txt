add_definitions(-DDBUS_COMPILATION)

SET(EFENCE "")
SET(BUS_DIR ${CMAKE_SOURCE_DIR}/../bus)

# config files for installation 
CONFIGURE_FILE( "${BUS_DIR}/session.conf.in" "${CMAKE_CURRENT_BINARY_DIR}/session.conf" IMMEDIATE @ONLY)
CONFIGURE_FILE( "${BUS_DIR}/legacy-config/session.conf.in" "${CMAKE_CURRENT_BINARY_DIR}/legacy-config/session.conf" IMMEDIATE @ONLY)
FILE(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/session.d)

if(NOT WIN32)
    CONFIGURE_FILE( "${BUS_DIR}/system.conf.in" "${CMAKE_CURRENT_BINARY_DIR}/system.conf" IMMEDIATE @ONLY)
    CONFIGURE_FILE( "${BUS_DIR}/legacy-config/system.conf.in" "${CMAKE_CURRENT_BINARY_DIR}/legacy-config/system.conf" IMMEDIATE @ONLY)
    FILE(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/system.d)
endif()

# copy services for local daemon start to local service dir data/dbus-1/services
SET (SERVICE_FILES test/data/valid-service-files)
FILE(GLOB FILES "${CMAKE_SOURCE_DIR}/../${SERVICE_FILES}/*.service.in" )
FOREACH(FILE ${FILES})	
	GET_FILENAME_COMPONENT(FILENAME ${FILE} NAME_WE)
	SET (TARGET ${CMAKE_BINARY_DIR}/data/dbus-1/services/${FILENAME}.service)
	IF (CONFIG_VERBOSE)
		MESSAGE("FROM: ${FILE}\nTO: ${TARGET}\n")
	ENDIF (CONFIG_VERBOSE)
	configure_file(${FILE} ${TARGET} )
ENDFOREACH(FILE)


if (DBUS_BUS_ENABLE_INOTIFY)
    set (DIR_WATCH_SOURCE ${BUS_DIR}/dir-watch-inotify.c)
elseif (DBUS_BUS_ENABLE_KQUEUE)
    set (DIR_WATCH_SOURCE ${BUS_DIR}/dir-watch-kqueue.c)
else (DBUS_BUS_ENABLE_INOTIFY)
    set (DIR_WATCH_SOURCE ${BUS_DIR}/dir-watch-default.c)
endif (DBUS_BUS_ENABLE_INOTIFY)

set (BUS_SOURCES 
	${BUS_DIR}/activation.c				
	${BUS_DIR}/activation.h				
	${BUS_DIR}/apparmor.c
	${BUS_DIR}/apparmor.h
	${BUS_DIR}/audit.c
	${BUS_DIR}/audit.h
	${BUS_DIR}/bus.c					
	${BUS_DIR}/bus.h					
	${BUS_DIR}/config-loader-expat.c
	${BUS_DIR}/config-parser.c				
	${BUS_DIR}/config-parser.h
	${BUS_DIR}/config-parser-common.c
	${BUS_DIR}/config-parser-common.h
#    ${BUS_DIR}/config-parser-trivial.c
	${BUS_DIR}/connection.c
	${BUS_DIR}/connection.h				
	${BUS_DIR}/containers.c
	${BUS_DIR}/containers.h
	${BUS_DIR}/desktop-file.c				
	${BUS_DIR}/desktop-file.h				
	${BUS_DIR}/dir-watch.h				
	${BUS_DIR}/dispatch.c				
	${BUS_DIR}/dispatch.h				
	${BUS_DIR}/driver.c				
	${BUS_DIR}/driver.h				
	${BUS_DIR}/expirelist.c				
	${BUS_DIR}/expirelist.h				
	${BUS_DIR}/policy.c				
	${BUS_DIR}/policy.h				
	${BUS_DIR}/selinux.h				
	${BUS_DIR}/selinux.c				
	${BUS_DIR}/services.c				
	${BUS_DIR}/services.h				
	${BUS_DIR}/signals.c				
	${BUS_DIR}/signals.h				
	${BUS_DIR}/test.c					
	${BUS_DIR}/test.h					
	${BUS_DIR}/utils.c					
	${BUS_DIR}/utils.h					
	${DIR_WATCH_SOURCE}
)
if(DBUS_ENABLE_STATS)
	list(APPEND BUS_SOURCES
		${BUS_DIR}/stats.c
		${BUS_DIR}/stats.h
	)
endif(DBUS_ENABLE_STATS)

include_directories(
	${CMAKE_BINARY_DIR}
	${CMAKE_SOURCE_DIR}/..
	${EXPAT_INCLUDE_DIR}
)

if(WIN32)
    set(DBUS_VER_INTERNAL_NAME "dbus-daemon")
    set(DBUS_VER_ORIGINAL_NAME "${DBUS_VER_INTERNAL_NAME}${CMAKE_EXECUTABLE_SUFFIX}")
    set(DBUS_VER_FILE_TYPE "VFT_APP")
    configure_file(${CMAKE_SOURCE_DIR}/../dbus/versioninfo.rc.in ${CMAKE_CURRENT_BINARY_DIR}/versioninfo-${DBUS_VER_INTERNAL_NAME}.rc)
    list(APPEND BUS_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/versioninfo-${DBUS_VER_INTERNAL_NAME}.rc)
endif()

add_executable(dbus-daemon ${BUS_SOURCES} ${BUS_DIR}/main.c)
target_link_libraries(dbus-daemon ${DBUS_INTERNAL_LIBRARIES} ${EXPAT_LIBRARIES})
set_target_properties(dbus-daemon PROPERTIES OUTPUT_NAME ${DBUS_DAEMON_NAME})
set_target_properties(dbus-daemon PROPERTIES COMPILE_FLAGS ${DBUS_INTERNAL_CLIENT_DEFINITIONS})

install(TARGETS dbus-daemon ${INSTALL_TARGETS_DEFAULT_ARGS})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/session.conf DESTINATION share/dbus-1)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/legacy-config/session.conf DESTINATION etc/dbus-1)
install(DIRECTORY DESTINATION share/dbus-1/session.d)
install(DIRECTORY DESTINATION share/dbus-1/services)

if(NOT WIN32)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/system.conf DESTINATION share/dbus-1)
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/legacy-config/system.conf DESTINATION etc/dbus-1)
    install(DIRECTORY DESTINATION share/dbus-1/system.d)
    install(DIRECTORY DESTINATION share/dbus-1/system-services)
    install(DIRECTORY DESTINATION var/run/dbus)
endif()

if (DBUS_SERVICE)
	set (dbus_service_SOURCES
	        ${BUS_DIR}/bus-service-win.c
	# TODO: add additional files
	#	${BUS_DIR}/service-main.c
	#	${BUS_SOURCES}
	)

    set(DBUS_VER_INTERNAL_NAME "dbus-service")
    set(DBUS_VER_ORIGINAL_NAME "${DBUS_VER_INTERNAL_NAME}${CMAKE_EXECUTABLE_SUFFIX}")
    set(DBUS_VER_FILE_TYPE "VFT_APP")
    configure_file(${CMAKE_SOURCE_DIR}/../dbus/versioninfo.rc.in ${CMAKE_CURRENT_BINARY_DIR}/versioninfo-${DBUS_VER_INTERNAL_NAME}.rc)
    list(APPEND dbus_service_SOURCES ${CMAKE_CURRENT_BINARY_DIR}/versioninfo-${DBUS_VER_INTERNAL_NAME}.rc)
	add_executable(dbus-service ${dbus_service_SOURCES} )
	target_link_libraries(dbus-service ${DBUS_INTERNAL_LIBRARIES} ${EXPAT_LIBRARIES})
	set_target_properties(dbus-service PROPERTIES COMPILE_FLAGS ${DBUS_INTERNAL_CLIENT_DEFINITIONS})
	install(TARGETS dbus-service ${INSTALL_TARGETS_DEFAULT_ARGS})
endif (DBUS_SERVICE)

set(LAUNCH_HELPER_SOURCES
    ${BUS_DIR}/config-loader-expat.c
    ${BUS_DIR}/config-parser-common.c
    ${BUS_DIR}/config-parser-trivial.c
    ${BUS_DIR}/desktop-file.c
    ${BUS_DIR}/utils.c
    ${BUS_DIR}/activation-helper.c
)

if(NOT WIN32)
	add_executable(dbus-daemon-launch-helper ${LAUNCH_HELPER_SOURCES} ${BUS_DIR}/activation-helper-bin.c )
	target_link_libraries(dbus-daemon-launch-helper ${DBUS_INTERNAL_LIBRARIES} ${EXPAT_LIBRARIES} )
endif(NOT WIN32)

if (DBUS_ENABLE_EMBEDDED_TESTS)
	set(SOURCES ${BUS_SOURCES} ${BUS_DIR}/test-main.c)
	add_test_executable(test-bus "${SOURCES}"  ${DBUS_INTERNAL_LIBRARIES} ${EXPAT_LIBRARIES})
	set_target_properties(test-bus PROPERTIES COMPILE_FLAGS ${DBUS_INTERNAL_CLIENT_DEFINITIONS})
	if (NOT WIN32)
		set(test_bus_system_SOURCES
			${BUS_DIR}/config-loader-expat.c
			${BUS_DIR}/config-parser-common.c
			${BUS_DIR}/config-parser-trivial.c
			${BUS_DIR}/utils.c
			${BUS_DIR}/test-system.c
		)
		add_test_executable(test-bus-system "${test_bus_system_SOURCES}" ${DBUS_INTERNAL_LIBRARIES} ${EXPAT_LIBRARIES} ${DBUS_BUS_LIBS})

		add_executable(dbus-daemon-launch-helper-test ${LAUNCH_HELPER_SOURCES}     ${BUS_DIR}/activation-helper-bin.c)
		set_target_properties(dbus-daemon-launch-helper-test PROPERTIES COMPILE_FLAGS "-DACTIVATION_LAUNCHER_TEST")
		target_link_libraries(dbus-daemon-launch-helper-test ${DBUS_INTERNAL_LIBRARIES} ${EXPAT_LIBRARIES} )

		set (SOURCES ${LAUNCH_HELPER_SOURCES} ${BUS_DIR}/test-launch-helper.c)
		add_test_executable(test-bus-launch-helper "${SOURCES}"  ${DBUS_INTERNAL_LIBRARIES} ${EXPAT_LIBRARIES})
		set_target_properties(test-bus-launch-helper PROPERTIES COMPILE_FLAGS "-DACTIVATION_LAUNCHER_TEST -DACTIVATION_LAUNCHER_DO_OOM")
		install_targets(/lib dbus-daemon-launch-helper)
	endif()
endif (DBUS_ENABLE_EMBEDDED_TESTS)

if(MSVC)
	project_source_group(${GROUP_CODE} bus_test_SOURCES dummy)
endif(MSVC)

## mop up the gcov files
#clean-local:
#	/bin/rm *.bb *.bbg *.da *.gcov || true

#install-data-hook:
#	$(mkinstalldirs) $(DESTDIR)/$(localstatedir)/run/dbus
#	$(mkinstalldirs) $(DESTDIR)/$(configdir)/system.d
#	$(mkinstalldirs) $(DESTDIR)/$(datadir)/dbus-1/services

##install_file(${configdir}/system.d FILE

#### Init scripts fun
#SCRIPT_IN_FILES=messagebus.in
#		rc.messagebus.in

## Red Hat start
#if DBUS_INIT_SCRIPTS_RED_HAT

#initddir=$(sysconfdir)/rc.d/init.d

#initd_SCRIPTS= 	
#	messagebus

#endif
# ## Red Hat end

## Slackware start
#if DBUS_INIT_SCRIPTS_SLACKWARE

#initddir=$(sysconfdir)/rc.d/

#initd_SCRIPTS= 	
#	rc.messagebus

#endif
## Slackware end

#MAN_IN_FILES=dbus-daemon.1.in
#man_MANS = dbus-daemon.1

#### Extra dist 

#EXTRA_DIST=$(CONFIG_IN_FILES) $(SCRIPT_IN_FILES) $(man_MANS) $(MAN_IN_FILES)
