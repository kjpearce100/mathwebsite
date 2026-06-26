<?php
function outputLine($theTitle, $theJoke)
	{
    ?>
<!-- <link href="http://www.math.ttu.edu/~pearce/jokes/jokes.css" rel="stylesheet" type="text/css"> -->
<div align="center" class="jokeColor"><?php echo $theTitle; ?> <p>&nbsp;&nbsp; &#151; <?php echo $theJoke; ?></a></div>
	<?php
    }
?>

<?php
function outputTable($theTitle, $theJoke)
	{
    ?>
<link href="http://www.math.ttu.edu/~pearce/jokes/jokes.css" rel="stylesheet" type="text/css">
<table border=1 width=432px cellpadding=5 align="center" >
	<tr>
    <td bgcolor=#E7E7E7><div align=center class="jokeTitle"><?php echo $theTitle; ?></div> <p> <div align="left" class="jokeColor" <?php echo $theJoke; ?></div></td>
    </tr>
</table>
	<?php
    }
?>