#!/bin/bash

cd /opt/whatsapp-birthday-lambda

echo "═══════════════════════════════════════════════════════════"
echo "  🔬 Nuclear Clean with Git Branch Workflow"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Step 1: Check Git status
echo "1️⃣ Checking Git status..."
if [ ! -d .git ]; then
    echo "❌ Not a git repository!"
    exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "⚠️  You have uncommitted changes!"
    echo ""
    git status --short
    echo ""
    read -p "Do you want to commit these changes first? (yes/no): " commit_first
    
    if [ "$commit_first" = "yes" ]; then
        echo ""
        read -p "Enter commit message: " commit_msg
        git add -A
        git commit -m "$commit_msg"
        echo "✅ Changes committed"
    else
        echo ""
        read -p "Do you want to stash these changes? (yes/no): " stash_changes
        if [ "$stash_changes" = "yes" ]; then
            git stash save "Pre-nuclear-clean stash $(date +%Y-%m-%d_%H:%M:%S)"
            echo "✅ Changes stashed"
        fi
    fi
fi

echo ""
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"
echo ""

# Step 2: Create new branch
echo "2️⃣ Creating new branch for nuclear clean..."
BRANCH_NAME="fix/funfacts-nuclear-clean-$(date +%Y%m%d)"
echo "Branch name: $BRANCH_NAME"
echo ""
read -p "Use this branch name? (yes/no, or enter custom name): " branch_confirm

if [ "$branch_confirm" != "yes" ]; then
    read -p "Enter custom branch name: " custom_branch
    BRANCH_NAME="$custom_branch"
fi

git checkout -b "$BRANCH_NAME"
echo "✅ Created and switched to branch: $BRANCH_NAME"
echo ""

# Step 3: Show what will be cleaned
echo "3️⃣ Pre-clean diagnostics..."
echo ""
echo "Current containers:"
docker-compose ps
echo ""
echo "Current images:"
docker images | grep whatsapp-birthday-lambda || echo "No project images found"
echo ""
echo "Disk space before clean:"
df -h /var/lib/docker 2>/dev/null || df -h /
echo ""

# Step 4: Confirm nuclear clean
echo "☢️  NUCLEAR CLEAN WARNING"
echo "═══════════════════════════════════════════════════════════"
echo "This will:"
echo "  ❌ Stop ALL containers"
echo "  ❌ Remove ALL containers"
echo "  ❌ Remove ALL Docker images for this project"
echo "  ❌ Clear ALL Docker build cache"
echo "  🔄 Rebuild everything from scratch"
echo ""
echo "You are on branch: $BRANCH_NAME"
echo "Main branch will NOT be affected yet"
echo ""
read -p "Proceed with nuclear clean? (type 'yes' to confirm): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Cancelled. Switching back to $CURRENT_BRANCH"
    git checkout "$CURRENT_BRANCH"
    git branch -d "$BRANCH_NAME" 2>/dev/null
    exit 0
fi

echo ""
echo "🚀 Starting nuclear clean process..."
echo ""

# Step 5: Stop all containers
echo "5️⃣ Stopping all containers..."
docker-compose down
sleep 2
echo "✅ Containers stopped"
echo ""

# Step 6: Remove project images
echo "6️⃣ Removing all project images..."
PROJECT_IMAGES=$(docker images | grep whatsapp-birthday-lambda | awk '{print $3}')
if [ -n "$PROJECT_IMAGES" ]; then
    echo "$PROJECT_IMAGES" | xargs -r docker rmi -f
    echo "✅ Project images removed"
else
    echo "ℹ️  No project images to remove"
fi
echo ""

# Step 7: Remove unused images
echo "7️⃣ Removing all unused images..."
docker image prune -a -f
echo "✅ Unused images removed"
echo ""

# Step 8: Remove build cache
echo "8️⃣ Removing Docker build cache..."
docker builder prune -a -f
echo "✅ Build cache removed"
echo ""

# Step 9: Clean Python cache
echo "9️⃣ Cleaning Python cache..."
find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find . -type f -name "*.pyc" -delete 2>/dev/null || true
find . -type f -name "*.pyo" -delete 2>/dev/null || true
echo "✅ Python cache cleaned"
echo ""

# Step 10: Show disk space recovered
echo "🔟 Disk space after clean:"
df -h /var/lib/docker 2>/dev/null || df -h /
echo ""

# Step 11: Rebuild containers
echo "1️⃣1️⃣ Rebuilding all containers (this will take a few minutes)..."
docker-compose build --no-cache --pull
BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
    echo "❌ Build failed!"
    echo "   Check the error above and fix before proceeding"
    echo "   You are still on branch: $BRANCH_NAME"
    exit 1
fi

echo "✅ Containers rebuilt successfully"
echo ""

# Step 12: Start services
echo "1️⃣2️⃣ Starting all services..."
docker-compose up -d
echo ""

# Step 13: Wait and check health
echo "1️⃣3️⃣ Waiting for services to start (15 seconds)..."
sleep 15
echo ""

echo "1️⃣4️⃣ Final status check..."
docker-compose ps
echo ""

# Step 14: Run tests
echo "1️⃣5️⃣ Running verification tests..."
echo ""

echo "Testing Python API:"
curl -s http://localhost:5000/health && echo " ✅" || echo " ❌"

echo "Testing wppconnect:"
curl -s http://localhost:3005/health && echo " ✅" || echo " ❌"

echo "Testing dashboard:"
curl -s http://localhost:8080/health && echo " ✅" || echo " ❌"

echo ""

# Step 15: Show next steps
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ Nuclear Clean Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📊 Current Status:"
echo "   Branch: $BRANCH_NAME"
echo "   Previous branch: $CURRENT_BRANCH"
echo ""
echo "🔍 Verification Steps:"
echo "   1. Check logs: docker-compose logs -f"
echo "   2. Test fun facts: bash /tmp/test_funfact_now.sh"
echo "   3. Check containers: docker-compose ps"
echo "   4. Test web UI: http://localhost:3000"
echo ""
echo "✅ Once verified, commit your changes:"
echo "   git add -A"
echo "   git commit -m \"fix: nuclear clean and rebuild containers\""
echo ""
echo "🔀 To merge back to $CURRENT_BRANCH:"
echo "   git checkout $CURRENT_BRANCH"
echo "   git merge $BRANCH_NAME"
echo "   git branch -d $BRANCH_NAME  # Delete branch after merge"
echo ""
echo "↩️  To rollback if something goes wrong:"
echo "   git checkout $CURRENT_BRANCH"
echo "   docker-compose up -d"
echo ""
echo "═══════════════════════════════════════════════════════════"
