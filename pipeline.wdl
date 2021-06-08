workflow DiffBind {
  input {
    # Sample sheet as CSV
    File csv

    # Width around summit (Default = 200 bp)
    Int summits = 200

    String dockerImage
  }

  call diffBind {
    input:
      csv = csv,
      summits = summits,
      dockerImage = dockerImage,
  }

  output {
    Outputs outputs = export.outputs
  }
}

task diffBind {
  input {
    File csv
    Int summits = 200
    String dockerImage
  }

  command <<<
    /scripts/diffBind.r '~{csv}' ~{summits}
  >>>

  runtime {
    docker: dockerImage
    disks: 'local-disk 250G HDD'
    memory: '4G'
    cpu: 1
  }

  output {
    File outBed = '~{outPrefix}_~{outSuffix}.bed'
    File 
    File 
  }
}