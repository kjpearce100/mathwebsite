<?php
      $dbFileName = array("quotes.db");
/*
The variable $dbFileName is an array of the paths to the quote databases.  The example above indicates that the database files are in the same directory as the script.  If you put them in a different directory, say quotes/, then this variable would look like:
$dbFileName = array("quotes/political.db","quotes/religious.db");
if you want to pull from one database, the array should look like:
$dbFileName = array("political.db");
*/
	$numDB = count($dbFileName);
/*
The variable $numDB informs the script how many quote databases to pull from.
*/
      $quoteType = 0;
/*
The variable $quoteType determines the type of quote generation.
quoteType = 0 displays a new random quote each time the page is loaded.
quoteType = 1 displays a new random quote every 60 minutes.
quoteType = 2 displays a new random quote every 24 hours.
quoteType = 3 displays a new random quote once every 7 days.
Settings 1, 2 & 3 are handled by storing a cookie. 
Use the included "del_cookie.php" script to delete the cookie while you are testing the script.
*/
      if ($numDB == 1)
      {
            $filename = $dbFileName[0];
      }else{
            $ranDB = rand(1, $numDB);
            $filename = $dbFileName[$ranDB-1];
      }
/*
This conditional Statement if ($numDB == 1){.... is picking the database from which to pull the quotes. If the variable $numDB is set to 1 it pulls the first db in the array.  You will notice that $dbFileName is set to 0.  This is because most languages consider 0 to be the first number when counting.
*/
      $lines = file($filename);
      $numQuotes = count ($lines);

      if ($quoteType == 0)
      {
            $ranNum = rand(1, $numQuotes);
      }elseif ($quoteType == 1){
		if (isset($_COOKIE['quoteNum'])) 
            {
                  $ranNum = $_COOKIE['quoteNum'];
            } else {
    		      $ranNum = rand(1, $numQuotes);
                  setcookie("quoteNum", $ranNum, time()+60*60);// One Hour
            }
	}elseif ($quoteType == 2){
		if (isset($_COOKIE['quoteNum'])) 
            {
                  $ranNum = $_COOKIE['quoteNum'];
            } else {
                  $ranNum = rand(1, $numQuotes);
                  setcookie("quoteNum", $ranNum, time()+60*60*24); //Twenty-four Hours
            }
	}elseif ($quoteType == 3){
		if (isset($_COOKIE['quoteNum'])) 
            {
                  $ranNum = $_COOKIE['quoteNum'];
            } else {
    		      $ranNum = rand(1, $numQuotes);
                  setcookie("quoteNum", $ranNum, time()+60*60*24*7); // Seven Days
            }
      }
/*
This conditional Statement if ($quoteType == 0){.... is determining the interval at which you want the quotes displayed.  This feature uses the Set Cookie function.  Which places a cookie in the users browser.
*/
	include ('func.php'); 
/*
include('func.php') references the HTML that will be output to the browser.
*/
      $line = $lines[$ranNum-1];
      $element = explode("::",$line);
      $theQuote = $element[0];
      $theRef = $element[1];
//    $output = outputLine($theQuote, $theRef);
      $output = outputTable($theQuote, $theRef);
/*
If you want to output using the Table, remove the // from the second $output line and place a // in front of the first $output line.  Thus uncommenting the second and commenting the first.
*/
      echo $output; // Echo's the output on your web page.
?>
