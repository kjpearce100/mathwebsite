<?php
setcookie ("quoteNum", "", time() - 3600);
echo "QuoteNum Cookie Deleted! <br>";
echo "Cookie set to: ".$_Cookie['quoteNum'];
?>