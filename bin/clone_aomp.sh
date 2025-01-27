#!/bin/bash
#
#  clone_aomp.sh:  Clone the repositories needed to build the aomp compiler.  
#                  Currently AOMP needs 14 repositories.
#
# --- Start standard header ----
function getdname(){
   local __DIRN=`dirname "$1"`
   if [ "$__DIRN" = "." ] ; then
      __DIRN=$PWD;
   else
      if [ ${__DIRN:0:1} != "/" ] ; then
         if [ ${__DIRN:0:2} == ".." ] ; then
               __DIRN=`dirname $PWD`/${__DIRN:3}
         else
            if [ ${__DIRN:0:1} = "." ] ; then
               __DIRN=$PWD/${__DIRN:2}
            else
               __DIRN=$PWD/$__DIRN
            fi
         fi
      fi
   fi
   echo $__DIRN
}
thisdir=$(getdname $0)
[ ! -L "$0" ] || thisdir=$(getdname `readlink "$0"`)
. $thisdir/aomp_common_vars
# --- end standard header ----

if [ "$thisdir" != "$AOMP_REPOS/$AOMP_REPO_NAME/bin" ] ; then
   echo
   echo "ERROR:  This clone_aomp.sh script is found in directory $thisdir "
   echo "        But it should be found at $AOMP_REPOS/$AOMP_REPO_NAME/bin because the value"
   echo "        of AOMP_REPOS is $AOMP_REPOS. Either the environment variable AOMP_REPOS"
   echo "        is wrong or the $AOMP_REPO_NAME repository was cloned to the wrong directory. Consider"
   echo "        moving this $AOMP_REPO_NAME repository to $AOMP_REPOS/$AOMP_REPO_NAME (prefered)  OR"
   echo "        set the environment variable AOMP_REPOS to the parent directory of the $AOMP_REPO_NAME"
   echo "        repository before running $0"
   echo
   exit 1
fi

function list_repo(){
repodirname=$AOMP_REPOS/$reponame
cd $repodirname
echo `git config --get remote.origin.url` "  " $COBRANCH "  " `git log --numstat --format="%h" |head -1`
}

function clone_or_pull(){
if [ "$LISTONLY" == 'list' ]; then
list_repo
return
fi

repodirname=$AOMP_REPOS/$reponame
echo
if [ -d $repodirname  ] ; then 
   echo "--- Pulling updates to existing dir $repodirname ----"
   echo "    We assume this came from an earlier clone of $repo_web_location/$reponame"
   # FIXME look in $repodir/.git/config to be sure 
   cd $repodirname
   #   undo the patch to hip before pulling more updates
   if [ "$reponame" == "$AOMP_HIP_REPO_NAME" ] ; then
      git checkout src
      if [ -f src/hip_module.cpp.orig ] ; then
         rm src/hip_module.cpp.orig
      fi
   fi
   #   undo the patch to rocr runtime before pulling more updates
   if [ "$reponame" == "$AOMP_ROCR_REPO_NAME" ] ; then
      git checkout src
      if [ -f src/CMakeLists.txt.orig ] ; then
         rm src/CMakeLists.txt.orig
      fi
   fi
   #   undo the patch to rocminfo cmake before pulling more updates
   if [ "$reponame" == "$AOMP_RINFO_REPO_NAME" ] ; then
      echo $PWD
      echo git checkout CMakeLists.txt
      git checkout CMakeLists.txt
   fi
   #   undo the comgr patch to rocm-compilersupport before pulling more updates
   if [ "$reponame" == "$AOMP_COMGR_REPO_NAME" ] ; then
      git checkout lib/comgr/src
      if [ -f lib/comgr/src/comgr-objdump.cpp.orig ] ; then
         rm lib/comgr/src/comgr-objdump.cpp.orig
      fi
   fi
   if [ "$STASH_BEFORE_PULL" == "YES" ] ; then
      if [ "$reponame" != "$AOMP_HCC_REPO_NAME" ] ; then
         git stash -u
      fi
   fi
   echo "git pull "
   git pull 
   echo "cd $repodirname ; git checkout $COBRANCH"
   git checkout $COBRANCH
   #echo "git pull "
   #git pull 
   if [ "$reponame" == "$AOMP_HCC_REPO_NAME" ] ; then
     #  undo the hcc_ppc_fp16.patch before pulling more updates
     echo git checkout include/kalmar_math.h
     git checkout include/kalmar_math.h
     echo "git submodule update"
     git submodule update
     echo "git pull"
     git pull
   fi
else 
   echo --- NEW CLONE of repo $reponame to $repodirname ----
   cd $AOMP_REPOS
   if [ "$reponame" == "$AOMP_HCC_REPO_NAME" ] ; then
     git clone --recursive -b $COBRANCH $repo_web_location/$reponame $reponame
   else
     echo git clone $repo_web_location/$reponame
     git clone $repo_web_location/$reponame $reponame
     echo "cd $repodirname ; git checkout $COBRANCH"
     cd $repodirname
     git checkout $COBRANCH
   fi
fi
cd $repodirname
echo git status
git status
}

mkdir -p $AOMP_REPOS

# ---------------------------------------
#  The following REPOS are in ROCm-Development
# ---------------------------------------
repo_web_location=$GITROCDEV

reponame=$AOMP_REPO_NAME
COBRANCH=$AOMP_REPO_BRANCH
LISTONLY=$1
if [ "$LISTONLY" == 'list' ]; then
list_repo
#clone_or_pull
fi

reponame=$AOMP_EXTRAS_REPO_NAME
COBRANCH=$AOMP_EXTRAS_REPO_BRANCH
clone_or_pull

reponame=$AOMP_PROJECT_REPO_NAME
COBRANCH=$AOMP_PROJECT_REPO_BRANCH
clone_or_pull

reponame=$AOMP_FLANG_REPO_NAME
COBRANCH=$AOMP_FLANG_REPO_BRANCH
clone_or_pull

reponame=$AOMP_HIP_REPO_NAME
COBRANCH=$AOMP_HIP_REPO_BRANCH
clone_or_pull

# ---------------------------------------
# The following repos are in RadeonOpenCompute
# ---------------------------------------
repo_web_location=$GITROC

reponame=$AOMP_LIBDEVICE_REPO_NAME
COBRANCH=$AOMP_LIBDEVICE_REPO_BRANCH
clone_or_pull

reponame=$AOMP_ROCT_REPO_NAME
COBRANCH=$AOMP_ROCT_REPO_BRANCH
clone_or_pull

reponame=$AOMP_ROCR_REPO_NAME
COBRANCH=$AOMP_ROCR_REPO_BRANCH
clone_or_pull

reponame=$AOMP_ATMI_REPO_NAME
COBRANCH=$AOMP_ATMI_REPO_BRANCH
clone_or_pull

reponame=$AOMP_HCC_REPO_NAME
COBRANCH=$AOMP_HCC_REPO_BRANCH
clone_or_pull

reponame=$AOMP_COMGR_REPO_NAME
COBRANCH=$AOMP_COMGR_REPO_BRANCH
clone_or_pull

reponame=$AOMP_RINFO_REPO_NAME
COBRANCH=$AOMP_RINFO_REPO_BRANCH
clone_or_pull
