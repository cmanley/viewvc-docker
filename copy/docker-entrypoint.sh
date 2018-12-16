#!/bin/bash

# Same paths as in Dockerfile and all should be readable using the same gid:
REPOSITORY_ROOTS='/opt/cvs /opt/svn'
REPOSITORY_ROOTS_MOUNTED=
REPOSITORY_GID=

# Get the mounted repository volumes and abort if they were not mounted read-only.
for root in $REPOSITORY_ROOTS; do
	#mount_opts=$(findmnt -no 'OPTIONS' "$root" 2>&1)	# part of util-linux package
	mount_opts=$(sed -En 's|^\S+\s+'"$root"'\s+\S+\s+(\S+).*|\1|p' < /proc/mounts)
	if [ -n "$mount_opts" ]; then
		readonly=$(echo "$mount_opts" | tr , "\n" | grep -F ro);
		if [ -z "$readonly" ]; then
			echo "$0: Aborting to protect you from your own bad habits because you didn't mount the volume $root read-only using the :ro attribute" >&2
			exit 1
		fi
		if [ -z "$REPOSITORY_ROOTS_MOUNTED" ]; then
			REPOSITORY_ROOTS_MOUNTED="$root"
			REPOSITORY_GID=$(stat -c%g "$root")
			echo "$0: Found mounted repository volume $root with gid $REPOSITORY_GID"
		else
			REPOSITORY_ROOTS_MOUNTED="$REPOSITORY_ROOTS_MOUNTED $root"
		fi
	fi
done

# Default entrypoint (as defined by Dockerfile CMD):
if [ "$(echo "$1" | cut -c1-6)" = 'viewvc' ] || [ "$1" = 'shell' ]; then

	# Set gid of viewvc so that it can read the host's volume
	if [ -n "$REPOSITORY_ROOTS_MOUNTED" ]; then
		VIEWVC_GID_SOURCE='given'
		if [ -z "$VIEWVC_GID" ]; then
			# VIEWVC_GID not given and volume was mounted, so read gid from mounted volume.
			VIEWVC_GID="$REPOSITORY_GID"
			VIEWVC_GID_SOURCE='determined'
		elif ! echo "$VIEWVC_GID" | grep -qE '^[0-9]{1,9}$'; then
			echo "$0: Bad gid syntax in VIEWVC_GID environment variable ($VIEWVC_GID)" >&2
			exit 1
		fi
		VIEWVC_GROUP=www-data
		current_gid=$(getent group "$VIEWVC_GROUP" | cut -d: -f3)
		if [ "$VIEWVC_GID" = "$current_gid" ]; then
			echo "$0: ViewVC is already configured to use the gid $VIEWVC_GID($VIEWVC_GROUP)"
		else
			conflicting_group_name=$(getent group "$VIEWVC_GID" | cut -d: -f1)
			if [ -z "$conflicting_group_name" ]; then	# no existing group has the requested gid
				if [ "$(id -u)" = '0' ]; then
					groupmod -g "$VIEWVC_GID" "$VIEWVC_GROUP"
					echo "$0: ViewVC gid set to $VIEWVC_GID($VIEWVC_GROUP)"
				else
					echo "$0: You need to run this script as root in order to add a new group" >&2
					exit 1
				fi
			else
				echo "$0: Can't use the $VIEWVC_GID_SOURCE VIEWVC_GID value ($VIEWVC_GID) as it already belongs to the group $conflicting_group_name" >&2
				#exit 1
			fi
		fi
	fi

	# Optionally set viewvc theme (template dir)
	if [ -n "$VIEWVC_THEME" ]; then
		templates_dir='/etc/viewvc/templates'
		if [ "$VIEWVC_THEME" != "${VIEWVC_THEME//[^a-zA-Z0-9_]/}" ]; then
			echo "Bad characters in theme name ($VIEWVC_THEME)!"
			exit 1
		fi
		if [ ! -d "$templates_dir/$VIEWVC_THEME" ]; then
			echo "$0: viewvc theme \"$VIEWVC_THEME\" does not exist"
			exit 1
		fi
		symlink="$templates_dir/current"
		current_theme=$(readlink -f "$symlink" | xargs basename)
		if [ -z "$current_theme" ]; then
			echo 'Failed to determine current theme!'
			exit 1
		fi
		if [ "$VIEWVC_THEME" = "$current_theme" ]; then
			echo "$0: viewvc theme is already \"$VIEWVC_THEME\""
		else
			rm "$symlink" && ln -s "$templates_dir/$VIEWVC_THEME" "$symlink"
			echo "$0: viewvc theme changed to \"$VIEWVC_THEME\""
		fi
	fi

	if [ "$1" = 'shell' ]; then
		# Enter the shell
		echo 'Start supervisord with: /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf'
		exec /bin/bash --rcfile <(echo 'alias ll="ls -al --color"')
	else
		# Start nginx and viewvc
		exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
	fi
else
	# All other entry points. Typically /bin/bash
	exec "$@"
fi
