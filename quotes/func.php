<?php
function outputLine($theQuote, $theRef)
	{
    ?>
<!-- <link href="http://www.math.ttu.edu/~pearce/quotes/quotes.css" rel="stylesheet" type="text/css"> -->
<div align="center" class="quoteColor"><?php echo $theQuote; ?> <p>&nbsp;&nbsp; &#151; <?php echo $theRef; ?></a></div>
	<?php
    }
?>

<?php
function outputTable($theQuote, $theRef)
	{
    ?>
<link href="http://www.math.ttu.edu/~pearce/quotes/quotes.css" rel="stylesheet" type="text/css">
<table border=1 width=300px align="center">
	<tr>
    <td bgcolor=#E7E7E7><div align="left" class="quoteColor"><?php echo $theQuote; ?> <p>&nbsp;&nbsp; &#151; <?php echo $theRef; ?></a></div></td>
    </tr>
</table>
	<?php
    }
?>