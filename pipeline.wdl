version 1.0

workflow DiffBind {
  input {
    # Sample sheet as CSV
    File csv
    Array[File]? files
    String contrast
    String? label = factor

    # Width around summit (Default = 200 bp)
    Int? summits = 200

    String? dockerImage = "quay.io/kdong2395/diffbind:dev"
  }

  call diffBind {
    input:
      csv = csv,
      files = files,
      contrast = contrast,
      label = label,
      summits = summits,
      dockerImage = dockerImage
  }

  output {
    File outTSV = diffBind.outTSV
    File outPDf = diffBind.outPDF
  }
}

task diffBind {
  input {
    File csv
    Array[File]? files
    Int summits
    String contrast
    String label
    String dockerImage
  }

  command <<<
    echo "Input csv location:" '~{csv}'
    Rscript /diffBind.r '~{csv}' ~{summits} ~{contrast} ~{label}
  >>>

  runtime {
    maxRetries: 0
    docker: dockerImage
    disks: 'local-disk 250G HDD'
    memory: '4G'
    cpu: 8
  }

  output {
    File outTSV = 'deseq_results.tsv'
    File outPDF = 'output.pdf'
  }
}
