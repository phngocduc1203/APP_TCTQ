<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Services\ProcrastinationDetectionService;

class DetectProcrastination extends Command
{
    protected $signature = 'procrastination:detect';
    protected $description = 'Phát hiện trì hoãn cho tất cả người dùng';

    protected ProcrastinationDetectionService $service;

    public function __construct(ProcrastinationDetectionService $service)
    {
        parent::__construct();
        $this->service = $service;
    }

    public function handle()
    {
        $this->info('🔍 Bắt đầu quét phát hiện trì hoãn...');
        
        $users = User::all();
        $totalAlerts = 0;
        
        $progressBar = $this->output->createProgressBar($users->count());
        $progressBar->start();

        foreach ($users as $user) {
            $alerts = $this->service->detectProcrastinationForUser($user);
            $totalAlerts += $alerts->count();
            $progressBar->advance();
        }

        $progressBar->finish();
        $this->newLine();
        $this->info("✅ Hoàn thành! Đã tạo {$totalAlerts} cảnh báo cho {$users->count()} người dùng.");
        
        return Command::SUCCESS;
    }
}