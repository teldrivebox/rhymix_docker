<?php
if (isset($_POST['run_install'])) {
    $repo = "https://github.com/rhymix/rhymix.git";
    $target = "/var/www/html";

    // 1. 사전 체크: Git이 설치되어 있는지 확인
    $gitCheck = shell_exec("which git");
    if (!$gitCheck) {
        die("<h2>❌ 오류: 서버에 git이 설치되어 있지 않습니다.</h2>");
    }

    // 2. 설치 진행 (기존 파일 삭제 -> 클론)
    echo "<h2>Rhymix 설치 시작...</h2>";
    
    // index.php 자기 자신을 포함하여 삭제 후 클론
    // Rhymix는 파일이 많으므로 클론 속도가 조금 걸릴 수 있습니다.
    $cmd = "find $target -mindepth 1 -delete && git clone $repo $target";
    $output = shell_exec($cmd . " 2>&1");

    // 3. Rhymix 필수 권한 설정 (UID 1000/1002 환경 고려)
    // files 폴더와 .htaccess 등을 위해 쓰기 권한이 필요합니다.
    shell_exec("chmod -R 707 $target/files 2>&1");

    echo "<h3>설치 로그:</h3>";
    echo "<pre style='background:#f4f4f4; padding:10px;'>$output</pre>";
    echo "<p>설치가 완료되었습니다. <b><a href='/'>여기를 클릭하여 Rhymix 설정을 시작하세요.</a></b></p>";
    exit;
}
?>

<div style="max-width: 600px; margin: 50px auto; font-family: sans-serif; border: 2px solid #3498db; padding: 30px; border-radius: 15px;">
    <h2 style="color: #2980b9;">Rhymix 자동 설치기</h2>
    <p>버튼을 누르면 <b>GitHub 공식 리포지토리</b>에서 최신 소스를 가져옵니다.</p>
    <p style="color: #e74c3c;">⚠️ 주의: 현재 폴더의 모든 파일이 삭제됩니다!</p>
    
    <form method="post">
        <button type="submit" name="run_install" 
                style="width: 100%; background: #3498db; color: white; border: none; padding: 15px; font-size: 18px; border-radius: 5px; cursor: pointer;">
            Rhymix 최신 버전 설치 시작
        </button>
    </form>
</div>