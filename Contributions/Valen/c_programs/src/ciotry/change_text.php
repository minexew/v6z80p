#!/usr/bin/php  -dsafe_mode=Off
<?php

// When you apply this patch to cio generated .c source,
// it will compile by SDCC just fine. 
// By default, sdcc can produce  errors:  "error 2: Initializer element is not constant"

if( !isset($argv[1]) ) { echo "No filename! Exited. \n"; die(); }
$inputFileName = $argv[1];


$obj = new C_Patch();
$obj->DoPatch($inputFileName);
exit(0);



// ------------
class C_Patch
{
    var $numPatches = 0;
    var $inputFileName;
        
    function DoPatch($inputFileName) 
    {
        $this->inputFileName = $inputFileName;
        //file_put_contents('game_1.c', "\n");

        $text = file_get_contents($this->inputFileName);
        
        $regexp = '/static const (\S*?)Vtbl CiVtbl_(\S*?) = {(' .
            //'\s*?' .
            '.*?' .
            ')}/s';
        $matches = array();
        $num_matches =  preg_match_all($regexp,  $text, $matches, PREG_SET_ORDER);
        
        
        $strInitVirtFunc =  "\n\n" .
                            "// This func is part of Valen patch for sdcc compatibility. \n" .
                            "// You must call this func at the start of your program.\n" .
                            "void ValenPatch_init_virt_tables(void) { \n";
        for($i=0; $i<$num_matches; $i++) {
            $text_inside = $matches[$i][3];
            
            
            $matches_2 = array();
            $num_matches_2 =  preg_match_all('/(\(void.*?self\)\)) (.*?)_(.*?)(\,|\n)/',  $text_inside, $matches_2, PREG_SET_ORDER);
            if($num_matches_2 == 0) continue;
            
            for($k=0; $k<$num_matches_2; $k++) {
                
                $name_of_virt_func = $matches_2[$k][3];  // e.g. 'Move'
                $name_of_var =  $matches[$i][2];
                $str_init_virt_table = 'CiVtbl_' . $name_of_var . '.' . strtolower($name_of_virt_func) . 
                            ' = ' . $matches_2[$k][1] . ' '. $matches_2[$k][2] . '_' . $matches_2[$k][3] .
                            ';';
                
                // add builded str to the C function body
                $strInitVirtFunc .= "\n    " . $str_init_virt_table . "\n";
                
                /*$text_inside_m =  preg_replace(, 'NOLL' , $text_inside);
                if($text_inside_m ==  $text_inside)
                    //if text was not replaced, continue witn next C block      .... { .... };
                    continue;*/
                    
                
                //file_put_contents('game_1.c',       $str_init_virt_table,  FILE_APPEND);
                //file_put_contents('game_1.c',       "\n\n\n",       FILE_APPEND);
            }
            
            $strOriginalBlock = $matches[$i][0];
            $strEditedBlock = $this->EditTheCodeBlock( $strOriginalBlock );
            if($this->numPatches > 0) $this->ReplaceStringInFile($strOriginalBlock, $strEditedBlock);
            //echo $strEditedBlock;
        }
        $strInitVirtFunc .= "} \n";
        $strInitVirtFunc .= "// Num patches applied:  $this->numPatches \n" ;
        
        echo "ValenPatch: Num patches applied:  $this->numPatches \n" ;
        
        file_put_contents($this->inputFileName,   $strInitVirtFunc, FILE_APPEND);
    }
    

    function EditTheCodeBlock($str)
    {
        
        // replace strings (expression), which raise errors, to the "NULL"
        $newStr = '';
        foreach(preg_split("/((\r?\n)|(\n?\r))/", $str) as $line) {    
            if( strpos($line, '))') == FALSE )
                $newStr .= $line . PHP_EOL;
            else {
                $isLineContainComma = strpos($line, ',');
                $newStr .= "    NULL";
                if($isLineContainComma) $newStr .= ",";
                $newStr .= "    //  forced to NULL" . PHP_EOL;
                
                $this->numPatches++;
            }
            
        } 
        $str =  $newStr;
        
        
        // remove "const"
         $str = str_replace("const", '', $str);
         
         $str = "\n" . "//  This C block was modified by Valen patch program. \n" . $str;
         return $str;
    }

    function ReplaceStringInFile($str1, $str2)
    {
        $file = $this->inputFileName;
        $text = file_get_contents($file);  
        $text = str_replace($str1, $str2, $text);
        file_put_contents($file,   $text);
    }

}// class
?>
