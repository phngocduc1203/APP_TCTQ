<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // Chạy phát hiện trì hoãn mỗi ngày lúc 9:00 sáng
        $schedule->command('procrastination:detect')
                 ->dailyAt('9:00')
                 ->withoutOverlapping()
                 ->onOneServer()
                 ->appendOutputTo(storage_path('logs/procrastination.log'));
        
        // Hoặc chạy 2 lần mỗi ngày (9:00 sáng và 6:00 chiều)
        // $schedule->command('procrastination:detect')
        //          ->twiceDaily(9, 18)
        //          ->withoutOverlapping()
        //          ->onOneServer();
        
        // Hoặc chạy mỗi 6 giờ một lần
        // $schedule->command('procrastination:detect')
        //          ->everySixHours()
        //          ->withoutOverlapping()
        //          ->onOneServer();
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}