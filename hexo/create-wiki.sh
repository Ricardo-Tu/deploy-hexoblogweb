#!/bin/bash
echo ====================================
echo Please select the command type: 
echo ====================================
echo 1.Create wiki page
echo 2.create independent wiki page with 
echo ====================================

read -r -p "Please select the command type: " input

case $input in
    [1])
        echo "You selected create wiki page"
        read -r -p "Please enter the wiki page name: " wikiName
        echo "You entered: $wikiName"
        hexo new wiki $wikiName
        ;;
    [2])
        echo "You selected create independent wiki page with"
        read -r -p "Please enter the wiki page name: " wikiName
        echo "You entered: $wikiName"
        hexo new page wiki $wikiName 
        ;;
    *)
        echo "Invalid input..."
        ;;
esac