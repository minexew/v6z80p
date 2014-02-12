#!/usr/bin/php  -dsafe_mode=Off
<?php

// sdcc can produce  errors on:  "error 2: Initializer element is not constant"
// You  need to apply this patch to cio generated .c source
// After patch is applyed, the SDCC will compille C source file, just fine.
// 

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
            
            //var_dump($text_inside);echo "----------------\n";
            
            $matches_2 = array();
            $num_matches_2 =  preg_match_all('/(\(void.*?self.*?\)\)) (.*?)_(.*?)(\,|\n)/',  $text_inside, $matches_2, PREG_SET_ORDER);
            if($num_matches_2 == 0) continue;
            
            for($k=0; $k<$num_matches_2; $k++) {
                
                $name_of_virt_func = $matches_2[$k][3];  // e.g. 'Move'
                $name_of_var =  $matches[$i][2];
                $str_init_virt_table = 'CiVtbl_' . $name_of_var . '.' 
                                  . $this->GetNameOf_FuncPointer_InsideVtable($name_of_virt_func) . 
                            ' = ' . $matches_2[$k][1] . ' '. $matches_2[$k][2] . '_' . $matches_2[$k][3] .
                            ';';
                
                // add builded str to the C function body
                $strInitVirtFunc .= "\n    " . $str_init_virt_table . "\n";
                

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
    
    function GetNameOf_FuncPointer_InsideVtable($name_of_virt_func) 
    {
        // Rulez: 'Move' to 'move'
        // 'ApplyBehavior' to 'applyBehavior'
        $matches = array();
        // match all capital letters
        $num_matches =  preg_match_all('/[A-Z]/', 
                                             $name_of_virt_func, $matches, 
                                             PREG_SET_ORDER
                                            );
         //var_dump($matches); echo $num_matches . "\n";  /* . $posComma . "\n" . $isLineContainComma . "\n";*/ echo "----------------\n";
            
        if($num_matches >= 2) {
            // change first letter to a lower letter
            $char = $name_of_virt_func[0];
            $char = strtolower($char);
            $name_of_virt_func[0] = $char;
            return $name_of_virt_func;
        }
        else {
            // just one capital letter
            return strtolower($name_of_virt_func);
        }
    }

    function EditTheCodeBlock($str)
    {
        
        // replace strings (expression), which raise errors, to the "NULL"
        $newStr = '';
        foreach(preg_split("/((\r?\n)|(\n?\r))/", $str) as $line) {    
            if( strpos($line, '))') == FALSE )
                $newStr .= $line . PHP_EOL;
            else {                 
                $posComma = strpos($line, ',');
                $strLen = strlen($line);
                $isLineContainComma = ($posComma == $strLen - 1) ? 1 : 0;
                
                //var_dump($line); echo $strLen . "\n" . $posComma . "\n" . $isLineContainComma . "\n"; echo "----------------\n";
                
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
