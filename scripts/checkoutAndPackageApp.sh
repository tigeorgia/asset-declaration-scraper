#!/bin/bash

BASEDIR=$PWD
SCRIPTS_FOLDER=$BASEDIR/scripts
JAVA_APP_FOLDER=$BASEDIR/DeclarationXmlParsing

# Downloading from Github the latest changes
#echo "Updating project from Github"
git checkout $1
git --work-tree=$BASEDIR --git-dir=$BASEDIR/.git pull origin $1

# Compile the Java application
echo "Compiling java project"
cd $JAVA_APP_FOLDER
if ([ ! -d "$JAVA_APP_FOLDER/bin" ]); then
    mkdir bin
fi
javac -d bin -sourcepath src -cp lib/saxon9he.jar src/declaration/Main.java

# Package the class files and libraries into a JAR file
echo "Creating JAR file"
cp MANIFEST.MF $JAVA_APP_FOLDER/bin
cp lib/saxon9he.jar $JAVA_APP_FOLDER/bin
cd $JAVA_APP_FOLDER/bin
#jar cf declarationXmlParsing.jar bin/* lib/*
if ([ ! -d "$JAVA_APP_FOLDER/bin/org" ]); then
    cp $JAVA_APP_FOLDER/resources/jar-in-jar-loader.zip .
    unzip jar-in-jar-loader.zip
fi
jar cvmf MANIFEST.MF declarationXmlParsing.jar declaration/Main.class declaration/DeclarationModel.class declaration/DeclarationVariableResolver.class org/* saxon9he.jar

# Deploying the newly created JAR file into the script folder
echo "Copying JAR file to the 'scripts' folder"
if ([ -f "$SCRIPTS_FOLDER/declarationXmlParsing.jar" ]); then
    rm $SCRIPTS_FOLDER/declarationXmlParsing.jar
fi

mv $JAVA_APP_FOLDER/bin/declarationXmlParsing.jar $SCRIPTS_FOLDER/declarationXmlParsing.jar

rm $JAVA_APP_FOLDER/bin/MANIFEST.MF
rm $JAVA_APP_FOLDER/bin/saxon9he.jar
