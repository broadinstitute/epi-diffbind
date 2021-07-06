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
  }

  command <<<
    echo "Input csv location:" '~{csv}'
    Rscript /diffBind.r '~{csv}' ~{summits} ~{contrast} ~{label}
  >>>

  runtime {
    maxRetries: 0
    docker: dockerImage
    disks: 'local-disk 250 HDD'
    memory: '4G'
    cpu: 16
  }

  output {
    File outTSV = 'deseq_results.tsv'
    File outPDF = 'output.pdf'
  }
}