#bin/bash

OLD_NAME='RKSyncCoreDataViewController';
NEW_NAME='RKHumanViewController';

for i in `find . -name '*.[h|m]' -or -name '*.plist' -or -name '*.xib' -or -name '*.pbxproj'` ; do
	sed -i .old s/${OLD_NAME}/${NEW_NAME}/g $i; 
done
find . -name '*old' -exec rm {} \;
for i in `find . -name "${OLD_NAME}*"` ; do mv $i `echo $i | sed "s/${OLD_NAME}/${NEW_NAME}/g"` ; done