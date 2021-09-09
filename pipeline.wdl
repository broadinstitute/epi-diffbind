version 1.0

workflow DiffBind {
  input {
    # Sample sheet as CSV
    File csv
    Array[File]? files
    String contrast
    String? label = "factor"

    # Width around summit (Default = 200 bp)
    Int? summits = 200

    String dockerImage = "quay.io/kdong2395/diffbind:master"
    Int? memory = 32
  }

  if (!defined(files)) {
    call getFiles {
      input:
        csv = csv,
        dockerImage = dockerImage
    }
    
    call diffBind {
      input:
        csv = csv,
        files = getFiles.files,
        contrast = contrast,
        label = label,
        summits = summits,
        dockerImage = dockerImage
        memory = getFiles.memory
    }
  }

  if (defined(files)) {
    call diffBind as diffBindJSON {
      input:
        csv = csv,
        files = files,
        contrast = contrast,
        label = label,
        summits = summits,
        dockerImage = dockerImage
        memory = memory
    }
  }

  output {
    File outTSV = select_first([diffBind.outTSV, diffBindJSON.outTSV])
    File outPDf = select_first([diffBind.outPDF, diffBindJSON.outPDF])
  }
}

task getFiles {
  input {
    File csv
    String dockerImage
  }

  command <<<
    Rscript /getPaths.r '~{csv}'
  >>>

  runtime {
    maxRetries: 0
    docker: dockerImage
    disks: 'local-disk 4 HDD'
    memory: '2G'
    cpu: 1
  }

  output {
    Array[String] files = read_lines("files.txt")
    Int memory = read_int('mem.txt')
  }
}

task diffBind {
  input {
    File csv
    Array[File]? files
    Int? summits
    String contrast
    String? label
    String dockerImage
    Int? memory 
  }

  command <<<
    echo "Input csv location:" '~{csv}'
    Rscript /diffBind.r '~{csv}' ~{summits} ~{contrast} ~{label}
  >>>

  runtime {
    maxRetries: 0
    docker: dockerImage
    disks: 'local-disk 250 HDD'
    memory: memory + 'G'
    cpu: 8
  }

  output {
    File outTSV = 'deseq_results.tsv'
    File outPDF = 'output.pdf'
  }
}