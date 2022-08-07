#
# Classes
#
class ihex {
    # Properties
    ############
    [string]$file
    [System.Collections.Generic.List[byte]]$dataBytes

    # Constructors
    ##############
    ihex() {
        $this.file = ""
        $this.dataBytes = @()
    }

    ihex($f) {
        $this.file = $f
        $this.dataBytes = @()
    }

    # Methods
    #########

    # Read file content
    [void]Read() {
        $fileContent = ""
        if ($this.file -ne "") {
            $fileContent = Get-Content($this.file)
        }
        else {
            Write-Error -Message "No file defined"
        }

        # Initial file format check before reading data bytes
        $this.CheckFileFormat($fileContent)
    }

    hidden [void]CheckFileFormat($fileContent) {
        foreach ($line in $fileContent) {
            # Check start code
            if (!$line.StartsWith(":")) {
                Write-Error -Message "Line $($line.ReadCount) starts not with start code "":"""
            }

            # Check line length
            $minLineLength = 11
            $maxLineLength = 521 # minLineLength + 255 data bytes
            if ($line.Length -lt $minLineLength) {
                Write-Error -Message "Line $($line.ReadCount) deceeds minimum line length (Expected: >= $minLineLength; Actual: $($line.Length))"
            }
            elseif ($line.Length -gt $maxLineLength) {
                Write-Error -Message "Line $($line.ReadCount) exceeds maximum line length (Expected: <= $maxLineLength; Actual: $($line.Length))"
            }
            elseif (($line.Length % 2) -ne 1) {
                Write-Error -Message "Line $($line.ReadCount) has incorrect byte notation (Expected: 00..FF)"
            }

            # Check Record type

            # Check end of file occurence - only once at the end of the file

            # Substring to exclude startcode
            [string[]]$bytestrings = ($line.Substring(1) -split "(..)") -ne ""

            # Check checksum
            $calculatedChecksum = $this.CalculateChecksum($bytestrings)
            $actualChecksum = $bytestrings[$bytestrings.Length - 1]
            if ($calculatedChecksum -ne $actualChecksum) {
                Write-Error -Message "Line $($line.ReadCount) has incorrect checksum (Expected: $calculatedChecksum; Actual: $actualChecksum)"
            }
        }
    }

    hidden [void]CheckLineFormat() {
        # Check byte count to actual data bytes

        # Check record type specific formatting

        # Check if address of previous line overlaps with actual line
    }

    hidden [string]CalculateChecksum($bytestrings) {
        $byteSum = 0x00

        # Calculate sum of bytes (exclude last byte with checksum)
        for ($i = 0; $i -lt ($bytestrings.Length - 1); $i++) {
            $byte = [byte]("0x" + $bytestrings[$i])

            $byteSum += $byte
        }

        # Invert sum -> add 1 -> mask to byte -> convert to hexadecimal 
        $checksum = "{0:X2}" -f (0xFF -band ((-bnot $byteSum) + 1))

        return $checksum
   }
}

#
# Configuration
#
# PowerShell
$ErrorActionPreference = "Stop"

#
# Get script location
#
$directory = $PSScriptRoot

#
# Read hexfile
# 
# Create object
[ihex]$hexfile = [ihex]::new("$directory\..\..\test\ihex_test.hex")

# Read file
$hexfile.Read()
